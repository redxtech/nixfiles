from __future__ import annotations

import json
import os
import subprocess
import time
import uuid
from pathlib import Path
from typing import Any

from graph import store_path
from state import RunnerError, read_json, write_json

LIMITS = ["--max-jobs", "1", "--cores", "1"]
FROZEN = ["--no-update-lock-file", *LIMITS]


class Nix:
    def __init__(self, repo: Path, directory: Path) -> None:
        self.repo = repo
        self.directory = directory

    def command(self, arguments: list[str], label: str) -> dict[str, Any]:
        prefix = self.directory / "commands" / (label + "-" + uuid.uuid4().hex)
        prefix.parent.mkdir(parents=True, exist_ok=True)
        write_json(prefix.with_suffix(".argv.json"), arguments)
        start = time.monotonic()
        with (
            prefix.with_suffix(".stdout").open("wb") as stdout,
            prefix.with_suffix(".stderr").open("wb") as stderr,
        ):
            result = subprocess.run(
                arguments, cwd=self.repo, stdout=stdout, stderr=stderr, check=False
            )
        record = {
            "exit": result.returncode,
            "seconds": time.monotonic() - start,
            "stdoutRef": str(prefix.with_suffix(".stdout")),
            "stderrRef": str(prefix.with_suffix(".stderr")),
        }
        write_json(prefix.with_suffix(".result.json"), record)
        return record

    def output_path(self, drv: str, output: str) -> str:
        result = self.command(
            ["nix-store", "--query", "--binding", output, store_path(drv), *LIMITS],
            "fixed-output",
        )
        if result["exit"] != 0:
            raise RunnerError("Nix could not resolve the fixed-output path.")
        return store_path(Path(result["stdoutRef"]).read_text().strip())

    def valid(self, paths: list[str]) -> set[str]:
        available: set[str] = set()
        for offset in range(0, len(paths), 256):
            group = [store_path(path) for path in paths[offset : offset + 256]]
            result = self.command(
                ["nix", "path-info", "--json", "--json-format", "1", *FROZEN, *group],
                "valid",
            )
            document = read_json(Path(result["stdoutRef"]))
            if not isinstance(document, dict):
                raise RunnerError("The path-info format is not supported.")
            if result["exit"] not in {0, 1} or any(
                path not in document for path in group
            ):
                raise RunnerError("The output-validity query failed.")
            available.update(path for path in group if document[path] is not None)
        return available

    def root(self, path: str) -> str:
        path = store_path(path)
        if path not in self.valid([path]):
            raise RunnerError("The root target is not valid.")
        root = self.directory / "roots" / Path(path).name
        root.parent.mkdir(parents=True, exist_ok=True)
        if root.is_symlink() and os.readlink(root) != path:
            raise RunnerError("The root path belongs to another target.")
        if root.exists() and not root.is_symlink():
            raise RunnerError("The root path is not a symlink.")
        if path.endswith(".drv"):
            # nix-instantiate registers the captured derivation without realizing its outputs
            expression = (
                '{ type = "derivation"; name = "captured"; outputName = "out"; drvPath = '
                + json.dumps(path)
                + "; }"
            )
            arguments = [
                "nix-instantiate",
                "--expr",
                expression,
                "--add-root",
                str(root),
                "--indirect",
                *LIMITS,
            ]
        else:
            arguments = [
                "nix-store",
                "--realise",
                path,
                "--add-root",
                str(root),
                "--indirect",
                *LIMITS,
            ]
        result = self.command(arguments, "root")
        if result["exit"] != 0 or not root.is_symlink() or os.readlink(root) != path:
            raise RunnerError("Nix did not create the requested root.")
        auto = (
            Path(os.environ.get("NIX_STATE_DIR", "/nix/var/nix")) / "gcroots" / "auto"
        )
        registered = any(
            entry.is_symlink() and os.readlink(entry) == str(root)
            for entry in auto.iterdir()
        )
        if not registered:
            raise RunnerError("The indirect root registration is missing.")
        return str(root)

    def final(self, hostname: str, accepted: dict[str, Any]) -> dict[str, Any]:
        installable = (
            ".#nixosConfigurations."
            + json.dumps(hostname)
            + ".config.system.build.toplevel"
        )
        evaluation = self.command(
            ["nix", "eval", "--raw", installable + ".drvPath", *FROZEN],
            "final-identity",
        )
        if evaluation["exit"] != 0:
            return {"verdict": "blocked", "command": evaluation}
        current = Path(evaluation["stdoutRef"]).read_text().strip()
        if current != accepted["identity"]["toplevel"]:
            return {
                "verdict": "deferred",
                "reason": "target_changed",
                "toplevel": current,
            }
        link = self.directory / "results" / ("final-" + uuid.uuid4().hex)
        link.parent.mkdir(parents=True, exist_ok=True)
        command = self.command(
            [
                "nix",
                "build",
                installable,
                *FROZEN,
                "--out-link",
                str(link),
                "--print-build-logs",
            ],
            "final-system",
        )
        if command["exit"] != 0:
            return {"verdict": "blocked", "command": command}
        if not link.is_symlink() or os.readlink(link) != accepted["identity"]["output"]:
            return {
                "verdict": "deferred",
                "reason": "target_changed_during_build",
                "command": command,
            }
        path = accepted["identity"]["output"]
        root = self.root(path)
        current_evaluation = self.command(
            ["nix", "eval", "--raw", installable + ".drvPath", *FROZEN],
            "final-postflight",
        )
        if current_evaluation["exit"] != 0:
            return {
                "verdict": "blocked",
                "command": current_evaluation,
                "buildCommand": command,
                "rootRef": root,
            }
        latest = Path(current_evaluation["stdoutRef"]).read_text().strip()
        if latest != accepted["identity"]["toplevel"]:
            return {
                "verdict": "deferred",
                "reason": "target_changed_after_build",
                "command": command,
                "rootRef": root,
            }
        return {
            "verdict": "complete",
            "command": command,
            "systemPath": path,
            "rootRef": root,
        }

    def build(self, targets: list[dict[str, str]], label: str) -> dict[str, Any]:
        if not targets or len(targets) > 128:
            raise RunnerError("The build batch must contain 1 to 128 targets.")
        paths = [store_path(target["path"]) for target in targets]
        before = self.valid(paths)
        pending = [target for target in targets if target["path"] not in before]
        result: dict[str, Any] = {"exit": 0}
        if pending:
            installables = []
            for target in pending:
                drv = store_path(target["drv"])
                output = target["output"]
                if (
                    not drv.endswith(".drv")
                    or not output
                    or not output.replace("-", "").replace("_", "").isalnum()
                ):
                    raise RunnerError("The build target is not supported.")
                installables.append(drv + "^" + output)
            prefix = self.directory / "results" / uuid.uuid4().hex
            prefix.parent.mkdir(parents=True, exist_ok=True)
            result = self.command(
                [
                    "nix",
                    "build",
                    *installables,
                    *FROZEN,
                    "--keep-going",
                    "--out-link",
                    str(prefix),
                    "--print-build-logs",
                ],
                label,
            )
        after = self.valid(paths)
        roots = {path: self.root(path) for path in sorted(after)}
        unresolved = sorted(set(paths) - after)
        return {
            "verdict": "complete"
            if result["exit"] == 0 and not unresolved
            else "blocked",
            "completedPaths": sorted(after),
            "unresolvedPaths": unresolved,
            "roots": roots,
            "command": result,
        }
