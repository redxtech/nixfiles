#!/usr/bin/env python3
"""Prepare Bitwarden for Voyager's managed sleep requests."""

import argparse
import fcntl
import json
import os
import re
import selectors
import signal
import stat
import subprocess
import sys
import tempfile
import time
from enum import StrEnum
from pathlib import Path
from typing import Any, NamedTuple

BUS = "org.freedesktop.DBus"
BUS_PATH = "/org/freedesktop/DBus"
LOGIN = "org.freedesktop.login1"
LOGIN_PATH = "/org/freedesktop/login1"
LOGIN_INTERFACE = LOGIN + ".Manager"
OBSERVER_UNIT = "voyager-sleep.service"
REQUEST_UNIT = "voyager-sleep-request.service"
SLEEP_UNITS = tuple(
    f"systemd-{operation}.service"
    for operation in ("suspend", "hibernate", "hybrid-sleep", "suspend-then-hibernate")
)


class LoginIdentity(NamedTuple):
    bus_id: str
    owner: str


class SleepError(Exception):
    pass


class CommandError(SleepError):
    def __init__(self, program: str, returncode: int, stderr: str) -> None:
        self.returncode, self.stderr = returncode, stderr.strip()
        super().__init__(f"{program} failed: {self.stderr}")


class SleepRefused(SleepError):
    pass


class Trigger(StrEnum):
    MANUAL = "manual"
    HIBERNATE = "hibernate"
    IDLE = "idle"
    LID = "lid"
    KEY = "sleep-key"


ERRORS = (SleepError, OSError, ValueError, KeyError)


def power_state(directory: Path = Path("/sys/class/power_supply")) -> str:
    found, unknown = False, False
    for supply in directory.iterdir():
        try:
            if (supply / "type").read_text().strip() == "Battery":
                continue
            online = (supply / "online").read_text().strip()
        except OSError:
            unknown = True
            continue
        if online == "1":
            return "ac"
        found = True
        unknown |= online != "0"
    return "battery" if found and not unknown else "unknown"


def variant(value: Any) -> Any:
    return value["data"] if isinstance(value, dict) and "type" in value else value


def exit_item(root: Any) -> int:
    pending, found = [root], []
    count = 0
    while pending:
        node = variant(pending.pop())
        count += 1
        if count > 128 or not isinstance(node, list) or len(node) != 3:
            raise SleepError("The application menu layout is invalid.")
        identifier, properties, children = node
        if not isinstance(properties, dict) or not isinstance(children, list):
            raise SleepError("The application menu node is invalid.")
        label = str(variant(properties.get("label", ""))).replace("_", "").lower()
        if label in {"exit", "quit", "exit bitwarden", "quit bitwarden"}:
            if not variant(properties.get("enabled", True)) or not variant(
                properties.get("visible", True)
            ):
                raise SleepError("The application Exit action is unavailable.")
            if type(identifier) is not int or not 0 <= identifier < 2**31:
                raise SleepError("The application Exit identifier is invalid.")
            found.append(identifier)
        pending.extend(children)
    if len(found) != 1:
        raise SleepError("Exactly one application Exit action is required.")
    return found[0]


class Native:
    def run(
        self,
        command: list[str],
        timeout: float = 10,
        *,
        env: dict[str, str] | None = None,
    ) -> str:
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=timeout,
                env=env,
                check=False,
            )
        except (OSError, subprocess.TimeoutExpired) as error:
            raise SleepError(f"Cannot complete {command[0]}.") from error
        if result.returncode:
            raise CommandError(command[0], result.returncode, result.stderr)
        return result.stdout

    def bus(self, args: list[str], *, user: bool = False) -> Any:
        reply = json.loads(
            self.run(
                [
                    "busctl",
                    "--user" if user else "--system",
                    "--json=short",
                    "--auto-start=no",
                    "--allow-interactive-authorization=no",
                    "--timeout=5",
                    "--",
                    *args,
                ]
            )
        )
        value = reply["data"]
        return (
            value[0]
            if reply["type"] in {"s", "o", "u", "i", "b"}
            and isinstance(value, list)
            and len(value) == 1
            else value
        )

    def call(
        self,
        service: str,
        path: str,
        interface: str,
        method: str,
        signature: str,
        *args: str,
        user: bool = False,
    ) -> Any:
        return self.bus(
            ["call", service, path, interface, method, signature, *args], user=user
        )

    def show(self, unit: str, properties: str, *, user: bool = False) -> dict[str, str]:
        output = self.run(
            [
                "systemctl",
                *(["--user"] if user else []),
                "show",
                unit,
                *["--property=" + name for name in properties.split(",")],
            ]
        )
        return dict(line.split("=", 1) for line in output.splitlines() if "=" in line)

    def unit(self) -> dict[str, str]:
        return self.show(
            "bitwarden.service",
            "ActiveState,MainPID,Result,ExecMainCode,ExecMainStatus,NRestarts,InvocationID",
            user=True,
        )

    def session(self) -> dict[str, str]:
        identifier = self.run(
            ["loginctl", "show-user", str(os.getuid()), "--property=Display", "--value"]
        ).strip()
        if not identifier.isdecimal():
            raise SleepError("A local graphical session is required.")
        output = self.run(
            [
                "loginctl",
                "show-session",
                identifier,
                "--property=Active",
                "--property=Remote",
                "--property=Type",
                "--property=LockedHint",
            ]
        )
        values = dict(line.split("=", 1) for line in output.splitlines() if "=" in line)
        if (
            values.get("Active") != "yes"
            or values.get("Remote") != "no"
            or values.get("Type") != "wayland"
        ):
            raise SleepError("The local graphical session is not active.")
        return {**values, "id": identifier}

    def boolean(self, name: str, *, owner: str = LOGIN) -> bool:
        value = self.bus(["get-property", owner, LOGIN_PATH, LOGIN_INTERFACE, name])
        if type(value) is not bool:
            raise SleepError("The logind property has an invalid type.")
        return value

    def hardware(self) -> tuple[str, bool | None, bool | None]:
        try:
            lid, docked = self.boolean("LidClosed"), self.boolean("Docked")
        except SleepError:
            lid, docked = None, None
        try:
            power = power_state()
        except OSError:
            power = "unknown"
        return power, lid, docked

    def login_identity(self) -> LoginIdentity:
        bus_id = self.bus(["call", BUS, BUS_PATH, BUS, "GetId"])
        owner = self.bus(["call", BUS, BUS_PATH, BUS, "GetNameOwner", "s", LOGIN])
        # unique names can be reused after a bus restart; fence the bus as well
        after = self.bus(["call", BUS, BUS_PATH, BUS, "GetId"])
        if (
            not isinstance(bus_id, str)
            or not re.fullmatch(r"[0-9a-f]{32}", bus_id)
            or bus_id != after
            or not isinstance(owner, str)
            or not re.fullmatch(r":[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)+", owner)
        ):
            raise SleepError("Cannot identify the system bus and logind instance.")
        return LoginIdentity(bus_id, owner)

    def require_login(self, identity: LoginIdentity) -> None:
        if self.login_identity() != identity:
            raise SleepError("The system bus or logind instance changed.")

    def sleep_ongoing(self, identity: LoginIdentity) -> bool:
        self.require_login(identity)
        preparing = self.boolean("PreparingForSleep", owner=identity.owner)
        ongoing = False
        for unit in SLEEP_UNITS:
            state = self.show(unit, "ActiveState,Job")
            active, job = state.get("ActiveState"), state.get("Job")
            if (
                active
                not in {
                    "active",
                    "activating",
                    "deactivating",
                    "reloading",
                    "inactive",
                    "failed",
                }
                or not isinstance(job, str)
                or (job != "" and not re.fullmatch(r"[1-9][0-9]*", job))
            ):
                raise SleepError(
                    "Cannot determine the native sleep state and pending jobs."
                )
            ongoing |= active not in {"inactive", "failed"} or job != ""
        # target cancellation can leave dependency jobs; reread logind after them
        preparing_after = self.boolean("PreparingForSleep", owner=identity.owner)
        self.require_login(identity)
        return preparing or ongoing or preparing_after

    def clean_exit(self, original: dict[str, str]) -> bool:
        current = self.unit()
        return (
            current["MainPID"] == "0"
            and current["ActiveState"] == "inactive"
            and current["InvocationID"] == original["InvocationID"]
            and current["NRestarts"] == original["NRestarts"]
            and current["Result"] == "success"
            and current["ExecMainCode"] == "1"
            and current["ExecMainStatus"] == "0"
            and not Path("/proc/" + original["MainPID"]).exists()
        )

    def quit(self, original: dict[str, str]) -> None:
        items = self.bus(
            [
                "get-property",
                "org.kde.StatusNotifierWatcher",
                "/StatusNotifierWatcher",
                "org.kde.StatusNotifierWatcher",
                "RegisteredStatusNotifierItems",
            ],
            user=True,
        )
        targets = []
        for item in items:
            service, separator, suffix = item.partition("/")
            owner = self.call(
                "org.freedesktop.DBus",
                "/org/freedesktop/DBus",
                "org.freedesktop.DBus",
                "GetNameOwner",
                "s",
                service,
                user=True,
            )
            pid = self.call(
                "org.freedesktop.DBus",
                "/org/freedesktop/DBus",
                "org.freedesktop.DBus",
                "GetConnectionUnixProcessID",
                "s",
                owner,
                user=True,
            )
            if pid == int(original["MainPID"]):
                targets.append(
                    (owner, "/" + suffix if separator else "/StatusNotifierItem")
                )
        if len(targets) != 1:
            raise SleepError("Cannot identify exactly one Bitwarden tray item.")
        owner, item = targets[0]
        menu = self.bus(
            ["get-property", owner, item, "org.kde.StatusNotifierItem", "Menu"],
            user=True,
        )
        _, root = self.call(
            owner,
            menu,
            "com.canonical.dbusmenu",
            "GetLayout",
            "iias",
            "0",
            "-1",
            "4",
            "label",
            "enabled",
            "visible",
            "type",
            user=True,
        )
        identifier = exit_item(root)
        if self.unit() != original:
            raise SleepError("Bitwarden changed during preparation.")
        # the void Event reply has no JSON payload to decode
        self.run(
            [
                "busctl",
                "--user",
                "--auto-start=no",
                "--timeout=5",
                "--",
                "call",
                owner,
                menu,
                "com.canonical.dbusmenu",
                "Event",
                "isvu",
                str(identifier),
                "clicked",
                "i",
                "0",
                str(int(time.time() * 1000) & 0xFFFFFFFF),
            ]
        )
        deadline = time.monotonic() + 15
        while not self.clean_exit(original):
            if time.monotonic() >= deadline:
                raise SleepError("Bitwarden did not exit cleanly before the deadline.")
            time.sleep(0.25)

    def lock(self, session: str) -> None:
        if self.session().get("LockedHint") != "yes":
            self.run(["noctalia", "msg", "session", "lock"])
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            current = self.session()
            if current["id"] != session:
                raise SleepError("The graphical session changed during preparation.")
            if current.get("LockedHint") == "yes":
                return
            time.sleep(0.25)
        raise SleepError("The screen lock did not complete.")

    def capable(self, trigger: Trigger) -> bool:
        method = (
            "CanHibernate"
            if trigger == Trigger.HIBERNATE
            else "CanSuspendThenHibernate"
        )
        return self.bus(["call", LOGIN, LOGIN_PATH, LOGIN_INTERFACE, method]) == "yes"

    def sleep(self, trigger: Trigger, identity: LoginIdentity) -> None:
        self.require_login(identity)
        method = "Hibernate" if trigger == Trigger.HIBERNATE else "SuspendThenHibernate"
        try:
            # gdbus preserves the refusal name so timeouts never become definite aborts
            self.run(
                [
                    "gdbus",
                    "call",
                    "--system",
                    "--timeout=5",
                    "--dest",
                    identity.owner,
                    "--object-path",
                    LOGIN_PATH,
                    "--method",
                    f"{LOGIN_INTERFACE}.{method}",
                    "false",
                ],
                env={**os.environ, "LC_ALL": "C"},
            )
        except CommandError as error:
            name = re.fullmatch(
                r"Error: GDBus\.Error:([A-Za-z0-9_.]+):[^\n]*", error.stderr
            )
            if (
                error.returncode == 1
                and name
                and name[1]
                in {
                    "org.freedesktop.login1.SleepVerbNotSupported",
                    "org.freedesktop.login1.OperationInProgress",
                    "org.freedesktop.login1.BlockedByInhibitorLock",
                    "org.freedesktop.DBus.Error.AccessDenied",
                    "org.freedesktop.DBus.Error.InteractiveAuthorizationRequired",
                }
            ):
                raise SleepRefused(f"Native sleep was refused: {name[1]}") from error
            raise
        self.require_login(identity)

    def restart(self) -> None:
        self.run(["systemctl", "--user", "start", "bitwarden.service"], timeout=40)
        if self.unit()["ActiveState"] != "active":
            raise SleepError("Bitwarden did not restart.")

    def notify(self, message: str) -> None:
        print(message, file=sys.stderr, flush=True)
        try:
            self.run(
                ["notify-send", "--urgency=critical", "Voyager sleep", message],
                timeout=3,
            )
        except SleepError:
            pass


class IdleLatch:
    def __init__(self, directory: Path) -> None:
        self.path, self.lock = directory / "idle.json", directory / "idle.lock"

    def update(self, session: str, idle: bool, order: int) -> None:
        # callbacks overlap, so a delayed idle callback must not overwrite newer activity
        descriptor = os.open(self.lock, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
        with os.fdopen(descriptor, "r+") as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            if self.path.exists():
                previous = json.loads(self.path.read_text())
                if previous.get("session") == session and previous["order"] > order:
                    return
            with tempfile.NamedTemporaryFile(
                mode="w", dir=self.path.parent, delete=False
            ) as output:
                temporary = Path(output.name)
                json.dump({"session": session, "idle": idle, "order": order}, output)
            try:
                temporary.replace(self.path)
            finally:
                temporary.unlink(missing_ok=True)

    def reached(self, session: str) -> bool:
        if not self.path.exists():
            return False
        value = json.loads(self.path.read_text())
        return value.get("session") == session and value.get("idle") is True


class Admission:
    def __init__(self, native: Native, executable: str) -> None:
        self.native, self.executable = native, executable

    def submit(self, trigger: Trigger) -> bool:
        if (
            self.native.show(OBSERVER_UNIT, "ActiveState", user=True).get("ActiveState")
            != "active"
        ):
            return False
        try:
            self.native.run(
                [
                    "systemd-run",
                    "--user",
                    "--quiet",
                    "--no-ask-password",
                    "--collect",
                    "--service-type=exec",
                    f"--unit={REQUEST_UNIT}",
                    f"--property=BindsTo={OBSERVER_UNIT}",
                    f"--property=After={OBSERVER_UNIT}",
                    "--property=PartOf=graphical-session.target noctalia.service",
                    "--property=Restart=no",
                    "--property=KillMode=control-group",
                    "--property=TimeoutStopSec=60",
                    "--property=UMask=0077",
                    "--",
                    self.executable,
                    "worker",
                    str(trigger),
                ],
                timeout=15,
            )
        except SleepError:
            return False
        return True


class Worker:
    def __init__(self, native: Native, directory: Path) -> None:
        self.native, self.latch = native, IdleLatch(directory)

    def eligible(self, trigger: Trigger, session: str) -> bool:
        power, lid, docked = self.native.hardware()
        if trigger == Trigger.IDLE:
            return power == "battery" and self.latch.reached(session)
        if trigger == Trigger.LID:
            return power == "battery" and lid is True and docked is False
        return True

    def wait(self, identity: LoginIdentity) -> None:
        # the successful RPC records logind's pending action before replying;
        # no busy sample is required when the worker was frozen for its lifetime
        while self.native.sleep_ongoing(identity):
            time.sleep(0.25)

    def run(self, trigger: Trigger) -> bool:
        running, restore = False, False
        try:
            session = self.native.session()["id"]
            identity = self.native.login_identity()
            if not self.eligible(trigger, session) or self.native.sleep_ongoing(
                identity
            ):
                raise SleepError("The sleep request is not eligible.")
            original = self.native.unit()
            if original["ActiveState"] not in {"active", "inactive", "failed"} or (
                original["ActiveState"] == "active"
            ) != (original["MainPID"] != "0"):
                raise SleepError("Bitwarden is changing state. Sleep is blocked.")
            running = original["MainPID"] != "0"
            if running:
                try:
                    self.native.quit(original)
                finally:
                    restore = self.native.clean_exit(original)
                if not restore:
                    raise SleepError("Bitwarden did not exit cleanly.")
            if not self.native.capable(trigger):
                raise SleepError(
                    "Native sleep is unavailable or requires additional authorization."
                )
            self.native.lock(session)
            if (
                self.native.session()["id"] != session
                or not self.eligible(trigger, session)
                or self.native.sleep_ongoing(identity)
            ):
                raise SleepError(
                    "The session or sleep eligibility changed during preparation."
                )
            # only a definite refusal or proven completion makes restoration safe again
            restore = False
            try:
                self.native.sleep(trigger, identity)
            except SleepRefused:
                restore = True
                raise
            self.wait(identity)
            restore = True
            raise SleepError(
                "The native sleep request ended, but its result is unavailable. Check the system journal."
            )
        except ERRORS as error:
            self.native.notify(str(error))
        except BaseException:
            restore = False
            raise
        finally:
            if running:
                try:
                    if (
                        not restore
                        or self.native.session()["id"] != session
                        or self.native.sleep_ongoing(identity)
                    ):
                        raise SleepError("Automatic Bitwarden restoration was skipped.")
                    current = self.native.unit()
                    if current["MainPID"] == "0" and current["ActiveState"] in {
                        "inactive",
                        "failed",
                    }:
                        self.native.restart()
                    elif current["ActiveState"] != "active":
                        raise SleepError("Bitwarden is changing state.")
                except ERRORS as error:
                    self.native.notify(
                        f"{error} If Bitwarden is closed, start it manually after native sleep has finished."
                    )
        return False


class Events:
    def __init__(self) -> None:
        self.selector = selectors.DefaultSelector()
        self.processes: list[subprocess.Popen] = []
        self.buffers: dict[int, bytearray] = {}
        self.ready: set[str] = set()

    def start(self, service: str, path: str) -> None:
        process = subprocess.Popen(
            ["gdbus", "monitor", "--system", "--dest", service, "--object-path", path],
            stdout=subprocess.PIPE,
            env={**os.environ, "LC_ALL": "C"},
        )
        self.processes.append(process)
        self.selector.register(process.stdout, selectors.EVENT_READ, service)
        self.buffers[process.stdout.fileno()] = bytearray()

    def poll(self, timeout: float) -> bool:
        changed = False
        for key, _ in self.selector.select(timeout):
            chunk = os.read(key.fd, 4096)
            if not chunk:
                raise SleepError("The power event observer stopped.")
            buffer = self.buffers[key.fd]
            buffer.extend(chunk)
            while b"\n" in buffer:
                raw, _, remaining = buffer.partition(b"\n")
                buffer[:] = remaining
                if len(raw) > 16384:
                    raise SleepError("The power event exceeded the message limit.")
                line = raw.decode("utf-8").strip()
                if line.startswith(f"The name {key.data} is owned by "):
                    if key.data in self.ready:
                        raise SleepError("The power event service changed owner.")
                    self.ready.add(key.data)
                elif line == f"The name {key.data} does not have an owner":
                    raise SleepError("The power event service is unavailable.")
                elif ".PropertiesChanged " in line:
                    changed = True
            if len(buffer) > 16384:
                raise SleepError("The power event exceeded the message limit.")
        return changed

    def wait_ready(self) -> None:
        deadline = time.monotonic() + 5
        while len(self.ready) < len(self.processes):
            self.poll(0.25)
            if time.monotonic() >= deadline:
                raise SleepError("The power event observer is not ready.")

    def close(self) -> None:
        for process in self.processes:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            process.stdout.close()
        self.selector.close()


class Observer:
    def __init__(self, native: Native, directory: Path, admission: Admission) -> None:
        self.native, self.admission = native, admission
        self.session, self.latch = native.session()["id"], IdleLatch(directory)
        self.previous = native.hardware()

    def hardware_change(self) -> None:
        current = self.native.hardware()
        previous, self.previous = self.previous, current
        if (
            current[0] == "battery"
            and previous[0] != "battery"
            and self.latch.reached(self.session)
        ):
            self.admission.submit(Trigger.IDLE)
        if previous[1] is False and current[1] is True:
            self.admission.submit(Trigger.LID)

    def run(self) -> None:
        self.latch.update(self.session, False, time.monotonic_ns())
        events = Events()
        try:
            events.start(LOGIN, LOGIN_PATH)
            events.start("org.freedesktop.UPower", "/org/freedesktop/UPower")
            events.wait_ready()
            self.native.run(["systemd-notify", "--ready"])
            self.hardware_change()
            while True:
                if events.poll(1):
                    self.hardware_change()
        finally:
            events.close()


def runtime_directory() -> Path:
    directory = Path(os.environ["XDG_RUNTIME_DIR"]) / "voyager-sleep"
    directory.mkdir(mode=0o700, exist_ok=True)
    info = directory.lstat()
    if (
        not stat.S_ISDIR(info.st_mode)
        or info.st_uid != os.getuid()
        or info.st_mode & 0o077
    ):
        raise SleepError("The sleep runtime directory is not private.")
    return directory


def executable() -> str:
    source = Path(__file__).resolve()
    wrapper = source.with_name("voyager-sleep")
    return str(wrapper if wrapper.exists() else source)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("observer").add_argument("--notify-socket", required=True)
    for name in ("idle-threshold", "active"):
        commands.add_parser(name)
    for name in ("request", "worker"):
        commands.add_parser(name).add_argument("trigger", choices=list(Trigger))
    args = parser.parse_args()
    order = time.monotonic_ns()
    native = Native()
    try:
        directory = runtime_directory()
        admission = Admission(native, executable())
        if args.command == "observer":
            # systemd-inhibit removes NOTIFY_SOCKET from its child's environment.
            os.environ["NOTIFY_SOCKET"] = args.notify_socket
            signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
            Observer(native, directory, admission).run()
            return 0
        if args.command == "worker":
            invocation = os.environ.get("INVOCATION_ID", "")
            if (
                not invocation
                or native.show(REQUEST_UNIT, "InvocationID", user=True).get(
                    "InvocationID"
                )
                != invocation
            ):
                raise SleepError("The worker must run inside the managed request unit.")
            signal.signal(signal.SIGTERM, lambda *_: sys.exit(1))
            return 0 if Worker(native, directory).run(Trigger(args.trigger)) else 1
        if args.command in {"active", "idle-threshold"}:
            latch = IdleLatch(directory)
            session = native.session()["id"]
            latch.update(session, args.command == "idle-threshold", order)
            if args.command == "active" or native.hardware()[0] != "battery":
                return 0
            trigger = Trigger.IDLE
        else:
            trigger = Trigger(args.trigger)
        if not admission.submit(trigger):
            raise SleepError(
                "The observer is unavailable or another sleep request owns the worker."
            )
        print(json.dumps({"accepted": True}))
        return 0
    except ERRORS as error:
        native.notify(str(error))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
