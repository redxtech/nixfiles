from __future__ import annotations

import hashlib
import os
import stat
import subprocess
from pathlib import Path
from typing import Any

from state import RunnerError, digest


def git(repo: Path, *arguments: str) -> bytes:
    return subprocess.run(
        ["git", "-C", str(repo), *arguments], check=True, capture_output=True
    ).stdout


def allowed_path(name: str) -> bool:
    path = Path(name)
    return (
        bool(name)
        and not path.is_absolute()
        and ".." not in path.parts
        and path.parts[0] not in {".git", "secrets"}
    )


def file_record(repo: Path, name: str) -> dict[str, Any] | None:
    if not allowed_path(name):
        raise RunnerError("The source path is outside the permitted scope.")
    path = repo / name
    if (
        not path.parent.resolve().is_relative_to(repo.resolve())
        or "secrets" in path.parent.resolve().relative_to(repo.resolve()).parts
    ):
        raise RunnerError("The source path has an unsafe parent.")
    try:
        info = path.lstat()
    except FileNotFoundError:
        return None
    if stat.S_ISLNK(info.st_mode):
        return {"kind": "symlink", "value": os.readlink(path)}
    if stat.S_ISREG(info.st_mode):
        return {
            "kind": "file",
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "executable": bool(info.st_mode & 0o111),
        }
    raise RunnerError("The source path is not a regular file or a symlink.")


def snapshot(repo: Path) -> dict[str, Any]:
    names = (
        git(repo, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
        .decode()
        .split("\0")
    )
    names = sorted({name for name in names if allowed_path(name)})
    index: dict[str, list[str]] = {}
    for item in git(repo, "ls-files", "--stage", "-z").decode().split("\0"):
        if not item:
            continue
        entry, name = item.split("\t", 1)
        if allowed_path(name):
            index.setdefault(name, []).append(entry)
    return {
        "head": git(repo, "rev-parse", "HEAD").decode().strip(),
        "branch": git(repo, "branch", "--show-current").decode().strip() or "DETACHED",
        "files": {name: file_record(repo, name) for name in names},
        "index": index,
    }


def reconcile(
    baseline: dict[str, Any],
    current: dict[str, Any],
    owned: dict[str, Any],
    input_paths: list[str],
) -> dict[str, Any]:
    files = baseline["files"]
    stages = baseline["index"]
    changed = sorted(
        name
        for name in files.keys() | current["files"].keys()
        if files.get(name) != current["files"].get(name)
    )
    indexed = sorted(
        name
        for name in stages.keys() | current["index"].keys()
        if stages.get(name) != current["index"].get(name)
    )
    conflicts = sorted(
        name
        for name, expected in owned.items()
        if current["files"].get(name) != expected
    )
    inputs = sorted(
        set(changed) & ({"flake.lock", "flake.nix"} | set(input_paths)) - set(owned)
    )
    return {
        "verdict": "blocked" if conflicts or inputs else "complete",
        "externalPaths": sorted((set(changed) | set(indexed)) - set(owned)),
        "ownedConflicts": conflicts,
        "inputChanges": inputs,
        "headChanged": baseline["head"] != current["head"],
        "branchChanged": baseline["branch"] != current["branch"],
        "checkTarget": bool(changed or set(stages) != set(current["index"])),
        "snapshotId": digest(current),
    }


def merge_proposal(
    base: Path, proposal: Path, current: Path, output: Path
) -> dict[str, Any]:
    result = subprocess.run(
        ["git", "merge-file", "--stdout", str(proposal), str(base), str(current)],
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        return {
            "verdict": "needs_input" if 0 < result.returncode < 128 else "blocked",
            "reason": "The repair overlaps an external edit.",
            "exit": result.returncode,
        }
    output.write_bytes(result.stdout)
    return {
        "verdict": "complete",
        "proposalRef": str(output),
        "sha256": hashlib.sha256(result.stdout).hexdigest(),
    }
