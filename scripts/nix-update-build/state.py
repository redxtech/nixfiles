from __future__ import annotations

import fcntl
import hashlib
import json
import os
import tempfile
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path
from typing import Any


class RunnerError(Exception):
    pass


def digest(value: Any) -> str:
    return hashlib.sha256(
        json.dumps(value, sort_keys=True, allow_nan=False).encode()
    ).hexdigest()


def read_json(path: Path) -> Any:
    return json.loads(path.read_text())


def write_json(path: Path, value: Any) -> None:
    data = json.dumps(value, sort_keys=True, indent=2, allow_nan=False) + "\n"
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


@contextmanager
def locked_run(directory: Path) -> Iterator[dict[str, Any]]:
    with (directory / "state.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = read_json(directory / "state.json")
        if state.get("version") != 1:
            raise RunnerError("The checkpoint version is not supported.")
        yield state
        write_json(directory / "state.json", state)


def request_decision(
    state: dict[str, Any], key: str, scope: dict[str, Any]
) -> dict[str, Any]:
    identity = digest(scope)
    decisions = state.setdefault("decisions", {})
    previous = decisions.get(key)
    if previous and previous["identity"] == identity:
        return {
            **previous,
            "ask": previous["status"] == "pending" and not previous["asked"],
        }
    if previous and previous["status"] == "pending":
        raise RunnerError("Resolve the pending decision before changing its scope.")
    decision = {
        "id": key,
        "identity": identity,
        "scope": scope,
        "status": "pending",
        "asked": False,
    }
    decisions[key] = decision
    return {**decision, "ask": True}


def recovery(
    state: dict[str, Any], failure: str, settled: bool, same_protocol: bool
) -> str:
    if not settled:
        return "reconcile_processes"
    if not same_protocol:
        return "needs_input"
    attempts = state.setdefault("recoveries", {})
    count = attempts.get(failure, 0)
    if count >= 3:
        return "blocked"
    attempts[failure] = count + 1
    return "resume_checkpoint"
