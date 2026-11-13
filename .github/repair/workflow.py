"""Prepare immutable repair context and validate proposals without model credentials."""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

from policy import SHA, TARGETS, apply_proposal, digest, prepare_records, require


def git(cwd, *args):
    return subprocess.check_output(["git", "-C", str(cwd), *args], text=True)


def load(path, limit=16 * 1024 * 1024):
    path = Path(path)
    require(path.stat().st_size <= limit, "The input file exceeds the size limit.")
    return json.loads(path.read_text())


def save(path, value):
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(json.dumps(value, sort_keys=True))


def source_files(cwd, sha):
    files = {}
    for entry in git(cwd, "ls-tree", "-r", sha).splitlines():
        metadata, path = entry.split("\t", 1)
        mode, kind, _ = metadata.split()
        if mode != "100644" or kind != "blob" or not path.endswith(".nix"):
            continue
        if not re.fullmatch(r"[A-Za-z0-9_./-]+", path) or path.startswith("secrets/"):
            continue
        text = git(cwd, "show", f"{sha}:{path}")
        if len(text.encode()) <= 65536 and "\x00" not in text:
            files[path] = text
    require(
        sum(len(text) for text in files.values()) <= 8 * 1024 * 1024,
        "The source snapshot exceeds the size limit.",
    )
    return files


def prepare(args):
    sha, base = os.environ["BUILD_REF"], os.environ["BASE_REF"]
    plan = {
        "sha": sha,
        "base": base,
        "pr": int(os.environ["REPAIR_PR"]),
        "eligible": False,
        "reason": "",
    }
    try:
        require(SHA.fullmatch(sha) and SHA.fullmatch(base), "Invalid source SHA.")
        require(
            git(args.candidate, "rev-parse", "HEAD").strip() == sha,
            "The candidate checkout does not match.",
        )
        require(
            git(args.candidate, "diff", "--name-only", base, sha).splitlines()
            == ["flake.lock"],
            "The update must change only flake.lock before repair.",
        )
        records = [
            load(path, 150000)
            for path in Path(args.diagnostics).glob("*/diagnostic.json")
        ]
        failures, eligible = prepare_records(records, sha)
        plan.update(failures=failures, eligible=eligible)
        plan["reason"] = (
            "A Nix evaluation or build failed. One bounded diagnosis is allowed."
            if eligible
            else "No repairable Nix failure was found. Infrastructure and upload failures do not permit source edits."
        )
        if eligible:
            old_lock = json.loads(git(args.candidate, "show", f"{base}:flake.lock"))
            new_lock = json.loads(git(args.candidate, "show", f"{sha}:flake.lock"))
            plan["inputs"] = {
                name: {
                    "before": old_lock["nodes"].get(name, {}).get("locked"),
                    "after": node.get("locked"),
                }
                for name, node in new_lock["nodes"].items()
                if old_lock["nodes"].get(name, {}).get("locked") != node.get("locked")
            }
            plan["files"] = source_files(args.candidate, sha)
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        plan.update(eligible=False, reason=f"Repair admission failed: {error}")
    save(args.output, plan)
    if output := os.environ.get("GITHUB_OUTPUT"):
        with open(output, "a") as stream:
            stream.write(f"eligible={str(plan['eligible']).lower()}\n")
    print(plan["reason"])


def check(args):
    plan, proposal = load(args.plan), load(args.proposal, 32768)
    outcome = {"allowed": False, "reason": "The proposal was not checked."}
    try:
        changes = apply_proposal(plan, proposal)
        outcome.update(
            allowed=bool(changes),
            reason="The rename policy passed."
            if changes
            else "The diagnosis requires owner review.",
        )
    except (ValueError, KeyError, TypeError, IndexError) as error:
        outcome["reason"] = f"The proposal failed the rename policy: {error}"
    save(args.output, outcome)
    if output := os.environ.get("GITHUB_OUTPUT"):
        with open(output, "a") as stream:
            stream.write(f"has-patch={str(outcome['allowed']).lower()}\n")
    print(outcome["reason"])


def apply_files(cwd, plan, proposal):
    require(plan["eligible"] is True, "The repair plan is not eligible.")
    require(
        git(cwd, "rev-parse", "HEAD").strip() == plan["sha"], "The source SHA changed."
    )
    require(
        not git(cwd, "status", "--porcelain"), "The candidate checkout is not clean."
    )
    changes = apply_proposal(plan, proposal)
    require(bool(changes), "The agent did not propose an automatic repair.")
    for path, text in changes.items():
        require(
            git(cwd, "show", f"{plan['sha']}:{path}") == plan["files"][path],
            "The source snapshot changed.",
        )
        destination = Path(cwd) / path
        require(
            destination.is_file() and not destination.is_symlink(),
            "The repair path is not a regular file.",
        )
        destination.write_text(text)
    subprocess.run(["git", "-C", str(cwd), "diff", "--check"], check=True)
    # the checkout belongs to this isolated validation job and has no unrelated index entries
    subprocess.run(["git", "-C", str(cwd), "add", "--", *changes], check=True)
    return changes, git(cwd, "write-tree").strip()


def validate(args):
    plan, proposal = load(args.plan), load(args.proposal, 32768)
    require(args.target in TARGETS, "The validation target is not allowed.")
    receipt = {
        "sha": plan["sha"],
        "base": plan["base"],
        "proposal": digest(proposal),
        "target": args.target,
        "success": False,
        "reason": "Validation did not complete.",
    }
    save(args.output, receipt)
    try:
        _, receipt["tree"] = apply_files(args.candidate, plan, proposal)
        capture = str(Path(__file__).with_name("capture.py").resolve())
        targets = {record["target"] for record in plan["failures"]}
        if args.target in targets:
            require(
                git(args.baseline, "rev-parse", "HEAD").strip() == plan["base"],
                "The baseline checkout does not match.",
            )
            env = {**os.environ, "BUILD_REF": plan["base"]}
            subprocess.run(
                [
                    sys.executable,
                    capture,
                    args.target,
                    "./result-baseline",
                    str(Path(args.output).parent / "baseline"),
                ],
                cwd=args.baseline,
                env=env,
                check=True,
            )
        env = {**os.environ, "BUILD_REF": plan["sha"]}
        subprocess.run(
            [
                sys.executable,
                capture,
                args.target,
                "./result-repair",
                str(Path(args.output).parent / "repaired"),
            ],
            cwd=args.candidate,
            env=env,
            check=True,
        )
        receipt.update(
            success=True,
            reason="The required baseline check and repaired target build passed.",
        )
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        receipt["reason"] = f"Repair validation failed: {error}"
    save(args.output, receipt)
    return 0 if receipt["success"] else 1


def bundle(args):
    plan, proposal = load(args.plan), load(args.proposal, 32768)
    changes, tree = apply_files(args.candidate, plan, proposal)
    receipts = [
        load(path, 4096) for path in Path(args.validation).glob("*/receipt.json")
    ]
    expected = {
        "sha": plan["sha"],
        "base": plan["base"],
        "proposal": digest(proposal),
        "tree": tree,
    }
    require(len(receipts) == len(TARGETS), "Validation receipts are missing.")
    require(
        {record.get("target") for record in receipts} == set(TARGETS),
        "Validation targets do not match.",
    )
    require(
        all(
            record.get("success") is True
            and all(record.get(key) == value for key, value in expected.items())
            for record in receipts
        ),
        "Not all targets passed for this exact repair tree.",
    )
    save(args.output, {**expected, "files": changes, "targets": TARGETS})


def main():
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    command = commands.add_parser("prepare")
    for name in ("candidate", "diagnostics", "output"):
        command.add_argument(f"--{name}", required=True)
    command = commands.add_parser("check")
    for name in ("plan", "proposal", "output"):
        command.add_argument(f"--{name}", required=True)
    command = commands.add_parser("validate")
    for name in ("candidate", "baseline", "plan", "proposal", "target", "output"):
        command.add_argument(f"--{name}", required=True)
    command = commands.add_parser("bundle")
    for name in ("candidate", "plan", "proposal", "validation", "output"):
        command.add_argument(f"--{name}", required=True)
    args = parser.parse_args()
    return {"prepare": prepare, "check": check, "validate": validate, "bundle": bundle}[
        args.command
    ](args)


if __name__ == "__main__":
    sys.exit(main())
