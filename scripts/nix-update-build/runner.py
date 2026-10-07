from __future__ import annotations

import argparse
import fcntl
import json
import os
import re
import subprocess
import sys
import uuid
from pathlib import Path
from typing import Any

from checkout import allowed_path, file_record, merge_proposal, reconcile, snapshot
from execution import LIMITS, Nix
from graph import normalize, plan
from state import (
    RunnerError,
    digest,
    locked_run,
    read_json,
    recovery,
    request_decision,
    write_json,
)


def artifact(directory: Path, label: str, value: Any) -> str:
    path = directory / "evidence" / (label + "-" + uuid.uuid4().hex + ".json")
    write_json(path, value)
    return str(path)


def initialize(
    repo: Path, directory: Path, hostname: str, input_paths: list[str]
) -> dict[str, Any]:
    repo = repo.resolve()
    directory = directory.resolve()
    if directory.is_relative_to(repo):
        raise RunnerError("The run directory must be outside the checkout.")
    if not re.fullmatch(r"[A-Za-z0-9._-]+", hostname):
        raise RunnerError("The hostname is not valid.")
    if any(not allowed_path(path) for path in input_paths):
        raise RunnerError("An input-definition path is not valid.")
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    if directory.stat().st_uid != os.getuid() or directory.stat().st_mode & 0o077:
        raise RunnerError("The run directory must be private and owned by this user.")
    with (directory / "state.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if (directory / "state.json").exists():
            raise RunnerError("The run directory already contains a checkpoint.")
        initial = artifact(directory, "initial", snapshot(repo))
        state = {
            "version": 1,
            "repo": str(repo),
            "hostname": hostname,
            "initialRef": initial,
            "currentRef": initial,
            "owned": {},
            "inputPaths": input_paths,
            "update": {"status": "pending"},
            "phase": "update",
            "decisions": {},
            "recoveries": {},
        }
        write_json(directory / "state.json", state)
    return {"verdict": "complete", "checkpointRef": str(directory / "state.json")}


def reconcile_run(directory: Path, state: dict[str, Any]) -> dict[str, Any]:
    current = snapshot(Path(state["repo"]))
    result = reconcile(
        read_json(Path(state["currentRef"])),
        current,
        state["owned"],
        state["inputPaths"],
    )
    result["evidenceRef"] = artifact(
        directory,
        "reconciliation",
        {"result": result, "snapshot": current, "baseRef": state["currentRef"]},
    )
    if result["verdict"] == "complete":
        state["currentRef"] = artifact(directory, "accepted", current)
        state["checkTarget"] = state.get("checkTarget", False) or result["checkTarget"]
    return result


def accept_input_state(
    directory: Path, state: dict[str, Any], evidence: Path, reason: str
) -> dict[str, Any]:
    if not reason.strip() or not evidence.resolve().is_relative_to(directory):
        raise RunnerError("Input acceptance needs run evidence and a selection reason.")
    inspection = read_json(evidence)
    if inspection.get("baseRef") != state["currentRef"]:
        raise RunnerError("The input inspection uses a stale baseline.")
    current = snapshot(Path(state["repo"]))
    if (
        digest(current) != inspection["result"]["snapshotId"]
        or current != inspection["snapshot"]
    ):
        raise RunnerError("The checkout changed after input inspection.")
    base = read_json(Path(state["currentRef"]))
    paths = sorted(
        path
        for path in {"flake.lock", "flake.nix", *state["inputPaths"]}
        if base["files"].get(path) != current["files"].get(path)
    )
    if not paths:
        raise RunnerError("The inspected snapshot contains no input changes.")
    # accept only selected input paths so another repair still needs its scoped acceptance
    for path in paths:
        for field in ("files", "index"):
            if path in current[field]:
                base[field][path] = current[field][path]
            else:
                base[field].pop(path, None)
        if path in state["owned"]:
            state["owned"][path] = current["files"].get(path)
    selected = artifact(
        directory,
        "input-selection",
        {
            "inspectionRef": str(evidence.resolve()),
            "reason": reason,
            "snapshotId": digest(current),
            "acceptedInputPaths": paths,
            "previousRef": state["currentRef"],
        },
    )
    state.setdefault("inputSelections", []).append(selected)
    state["currentRef"] = artifact(directory, "inputs-accepted", base)
    state["checkTarget"] = True
    state.pop("planRef", None)
    state["phase"] = "plan" if state["update"]["status"] == "complete" else "update"
    return {"verdict": "complete", "evidenceRef": selected, "acceptedInputPaths": paths}


def dispatch(args: argparse.Namespace) -> dict[str, Any]:
    directory = args.run_dir.resolve()
    if args.action == "init":
        return initialize(args.repo, directory, args.hostname, args.input_path)
    with locked_run(directory) as state:
        repo = Path(state["repo"])
        nix = Nix(repo, directory)
        if args.action == "status":
            return state
        if args.action == "reconcile":
            return reconcile_run(directory, state)
        if args.action == "accept-input-state":
            return accept_input_state(directory, state, args.evidence, args.reason)
        if args.action == "own":
            if state.get("activeOwned"):
                raise RunnerError("A writer scope is already active.")
            result = reconcile_run(directory, state)
            if result["verdict"] != "complete":
                return result
            for name in args.paths:
                if not allowed_path(name) or name in {"flake.nix", "flake.lock"}:
                    raise RunnerError("The repair path is not permitted.")
                state["owned"][name] = file_record(repo, name)
                record = state["owned"][name]
                if record is not None and record["kind"] != "file":
                    raise RunnerError("A writer base must be a regular file.")
                base = directory / "evidence" / ("writer-base-" + uuid.uuid4().hex)
                base.write_bytes((repo / name).read_bytes() if record else b"")
                state.setdefault("writerBaseFiles", {})[name] = str(base)
            state["activeOwned"] = args.paths
            state["writerBaseRef"] = state["currentRef"]
            return {
                "verdict": "complete",
                "writerBaseRef": state["writerBaseRef"],
                "writerBaseFiles": state["writerBaseFiles"],
            }
        if args.action == "accept-owned":
            # the parent invokes this only after inspecting the approved writer diff
            base = read_json(Path(state["currentRef"]))
            current = snapshot(repo)
            active = state.get("activeOwned", [])
            if not active:
                raise RunnerError("There is no approved writer scope.")
            expected = {
                **state["owned"],
                **{name: current["files"].get(name) for name in active},
            }
            result = reconcile(base, current, expected, state["inputPaths"])
            writer_base = read_json(Path(state["writerBaseRef"]))
            staged = sorted(
                name
                for name in active
                if writer_base["index"].get(name) != current["index"].get(name)
            )
            if staged:
                result.update(verdict="blocked", ownedIndexChanges=staged)
            if result["verdict"] != "complete":
                return result
            state["owned"] = expected
            state["activeOwned"] = []
            state["currentRef"] = artifact(directory, "repair-accepted", current)
            state["checkTarget"] = True
            return {"verdict": "complete", "sourceId": digest(current)}
        if args.action == "decision":
            result = request_decision(state, args.key, read_json(args.scope))
            decision = state["decisions"][args.key]
            if args.status == "asked":
                decision["asked"] = True
            elif args.status == "resolved":
                if not args.resolution:
                    raise RunnerError("A decision resolution is required.")
                decision.update(status="resolved", resolution=args.resolution)
            return {
                **result,
                **decision,
                "ask": result["ask"] and args.status == "request",
            }
        if args.action == "recover":
            return {
                "verdict": recovery(
                    state, args.failure, args.settled, not args.change_protocol
                ),
                "phase": state["phase"],
                "update": state["update"],
            }
        if args.action == "checkpoint":
            result = read_json(args.result)
            if result.get("verdict") not in {
                "complete",
                "blocked",
                "needs_input",
                "deferred",
            }:
                raise RunnerError("The result verdict is not valid.")
            state["phase"] = args.phase
            state["resultRef"] = artifact(directory, "result", result)
            return {
                "verdict": result["verdict"],
                "checkpointRef": str(directory / "state.json"),
            }
        if args.action == "plan":
            reconciliation = reconcile_run(directory, state)
            if reconciliation["verdict"] != "complete":
                return reconciliation
            result = plan(
                normalize(read_json(args.graph)),
                args.toplevel,
                nix.valid,
                args.batch_size,
                nix.output_path,
            )
            result["identity"].update(
                source=args.source,
                hostname=state["hostname"],
                snapshotId=digest(read_json(Path(state["currentRef"]))),
            )
            result["planId"] = digest(
                {"graphPlanId": result["planId"], "identity": result["identity"]}
            )
            result["graphRef"] = str(args.graph.resolve())
            result["roots"] = {
                path: nix.root(path)
                for path in [
                    args.source,
                    result["identity"]["toplevel"],
                    *result["boundaries"],
                ]
            }
            for batch in result.pop("batches"):
                ref = artifact(
                    directory, batch["id"], {"planId": result["planId"], **batch}
                )
                result.setdefault("segments", []).append(
                    {key: batch[key] for key in ("id", "deps", "heavy")}
                    | {"manifestRef": ref}
                )
            result.setdefault("segments", [])
            state["planRef"] = artifact(directory, "plan", result)
            state["phase"] = "components"
            return {"verdict": "complete", "planRef": state["planRef"], **result}
    raise RunnerError("The action is not supported.")


def update(directory: Path) -> dict[str, Any]:
    with locked_run(directory) as state:
        if state["update"]["status"] == "complete":
            return {"verdict": "complete", "reused": True, **state["update"]}
        if state["update"]["status"] != "pending":
            return {
                "verdict": "blocked",
                "reason": "Inspect the saved update command before any retry.",
            }
        result = reconcile_run(directory, state)
        if result["verdict"] != "complete":
            return result
        state["update"] = {"status": "running"}
        repo = Path(state["repo"])
    command = Nix(repo, directory).command(
        ["nix", "flake", "update", *LIMITS], "update"
    )
    with locked_run(directory) as state:
        state["update"] = {
            "status": "complete" if command["exit"] == 0 else "blocked",
            "command": command,
        }
        if command["exit"] == 0:
            state["owned"]["flake.lock"] = file_record(repo, "flake.lock")
            reconciliation = reconcile_run(directory, state)
            if reconciliation["verdict"] != "complete":
                return reconciliation
            state["phase"] = "plan"
    return {
        "verdict": "complete" if command["exit"] == 0 else "blocked",
        "command": command,
    }


def build(directory: Path, manifest: Path) -> dict[str, Any]:
    with locked_run(directory) as state:
        result = reconcile_run(directory, state)
        if result["verdict"] != "complete":
            return result
        accepted = read_json(Path(state["planRef"]))
        batch = read_json(manifest)
        if batch["planId"] != accepted["planId"] or str(manifest.resolve()) not in {
            segment["manifestRef"] for segment in accepted["segments"]
        }:
            raise RunnerError("The build manifest does not match the accepted plan.")
        repo = Path(state["repo"])
    # build admission stays with the parent so filesystem locks do not occupy waiting child slots
    result = Nix(repo, directory).build(batch["targets"], batch["id"])
    with locked_run(directory) as state:
        state.setdefault("batches", {}).setdefault(batch["planId"], {})[batch["id"]] = (
            artifact(directory, "built", result)
        )
    return result


def final(directory: Path) -> dict[str, Any]:
    with locked_run(directory) as state:
        reconciliation = reconcile_run(directory, state)
        if reconciliation["verdict"] != "complete":
            return reconciliation
        accepted = read_json(Path(state["planRef"]))
        completed = state.get("batches", {}).get(accepted["planId"], {})
        paths = set(accepted["boundaries"])
        for segment in accepted["segments"]:
            if (
                segment["id"] not in completed
                or read_json(Path(completed[segment["id"]]))["verdict"] != "complete"
            ):
                return {
                    "verdict": "blocked",
                    "reason": "Current-plan component coverage is incomplete.",
                }
            paths.update(
                target["path"]
                for target in read_json(Path(segment["manifestRef"]))["targets"]
            )
        repo = Path(state["repo"])
        hostname = state["hostname"]
    nix = Nix(repo, directory)
    if nix.valid(sorted(paths)) != paths:
        return {"verdict": "deferred", "reason": "required_outputs_disappeared"}
    for path in sorted(paths):
        nix.root(path)
    result = nix.final(hostname, accepted)
    with locked_run(directory) as state:
        result["reconciliation"] = reconcile_run(directory, state)
        if result["reconciliation"]["verdict"] != "complete":
            result["verdict"] = "blocked"
        state["finalRef"] = artifact(directory, "final", result)
        state["phase"] = "report" if result["verdict"] == "complete" else "plan"
    return result


def parser() -> argparse.ArgumentParser:
    root = argparse.ArgumentParser(
        description="Run deterministic Nix update and build bookkeeping."
    )
    root.add_argument("--run-dir", required=True, type=Path)
    commands = root.add_subparsers(dest="action", required=True)
    init = commands.add_parser("init")
    init.add_argument("--repo", required=True, type=Path)
    init.add_argument("--hostname", required=True)
    init.add_argument("--input-path", action="append", default=[])
    for name in ("status", "reconcile", "accept-owned", "update", "final"):
        commands.add_parser(name)
    accept_inputs = commands.add_parser("accept-input-state")
    accept_inputs.add_argument("--evidence", required=True, type=Path)
    accept_inputs.add_argument("--reason", required=True)
    own = commands.add_parser("own")
    own.add_argument("paths", nargs="+")
    decision = commands.add_parser("decision")
    decision.add_argument("--key", required=True)
    decision.add_argument("--scope", required=True, type=Path)
    decision.add_argument(
        "--status", choices=("request", "asked", "resolved"), default="request"
    )
    decision.add_argument("--resolution")
    recover = commands.add_parser("recover")
    recover.add_argument("--failure", required=True)
    recover.add_argument("--settled", action="store_true")
    recover.add_argument("--change-protocol", action="store_true")
    checkpoint = commands.add_parser("checkpoint")
    checkpoint.add_argument("--phase", required=True)
    checkpoint.add_argument("--result", required=True, type=Path)
    planner = commands.add_parser("plan")
    planner.add_argument("--graph", required=True, type=Path)
    planner.add_argument("--toplevel", required=True)
    planner.add_argument("--source", required=True)
    planner.add_argument("--batch-size", type=int, default=32)
    builder = commands.add_parser("build")
    builder.add_argument("--manifest", required=True, type=Path)
    merge = commands.add_parser("merge")
    for field in ("base", "proposal", "current", "output"):
        merge.add_argument("--" + field, required=True, type=Path)
    return root


def main() -> int:
    args = parser().parse_args()
    try:
        if args.action == "update":
            result = update(args.run_dir.resolve())
        elif args.action == "final":
            result = final(args.run_dir.resolve())
        elif args.action == "build":
            result = build(args.run_dir.resolve(), args.manifest.resolve())
        elif args.action == "merge":
            for path in (args.base, args.proposal, args.current, args.output):
                if not path.resolve().is_relative_to(args.run_dir.resolve()):
                    raise RunnerError("All merge files must stay in the run directory.")
            result = merge_proposal(args.base, args.proposal, args.current, args.output)
        else:
            result = dispatch(args)
        print(json.dumps(result, allow_nan=False))
        return (
            0
            if result.get("verdict")
            in {None, "complete", "resume_checkpoint", "reconcile_processes"}
            else 2
        )
    except (
        RunnerError,
        OSError,
        ValueError,
        KeyError,
        subprocess.CalledProcessError,
    ) as error:
        print(json.dumps({"verdict": "blocked", "error": str(error)}))
        return 2


if __name__ == "__main__":
    sys.exit(main())
