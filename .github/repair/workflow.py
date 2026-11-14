"""Prepare immutable repair context and validate proposals without model credentials."""

import argparse
import difflib
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
        if (
            mode != "100644"
            or kind != "blob"
            or not (
                path.endswith(".nix")
                or path.startswith("packages/")
                and path.endswith(".patch")
            )
        ):
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
        "attempt": 1,
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
            load(path, 524288)
            for path in Path(args.diagnostics).glob("*/diagnostic.json")
        ]
        failures, eligible = prepare_records(records, sha)
        plan.update(
            failures=failures,
            eligible=eligible,
            baselineTargets=[record["target"] for record in failures],
        )
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
            reason="The compatibility repair policy passed."
            if changes
            else "The diagnosis requires owner review.",
        )
    except (ValueError, KeyError, TypeError, IndexError) as error:
        outcome["reason"] = f"The proposal failed the repair policy: {error}"
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
        "attempt": plan.get("attempt", 1),
        "target": args.target,
        "complete": False,
        "stage": "policy",
        "baseline": "not-required",
        "repaired": "not-run",
        "success": False,
        "reason": "Validation did not complete.",
    }
    save(args.output, receipt)
    try:
        _, receipt["tree"] = apply_files(args.candidate, plan, proposal)
        capture = str(Path(__file__).with_name("capture.py").resolve())
        targets = plan.get(
            "baselineTargets", [record["target"] for record in plan["failures"]]
        )
        if args.target in targets:
            receipt.update(stage="baseline", baseline="incomplete")
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
            receipt["baseline"] = "passed"
        receipt["stage"] = "repaired"
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
            complete=True,
            repaired="passed",
            reason="The required baseline check and repaired target build passed.",
        )
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        receipt["reason"] = f"Repair validation failed: {error}"
        stage = receipt["stage"]
        diagnostic = Path(args.output).parent / stage / "diagnostic.json"
        if diagnostic.exists() and load(diagnostic, 524288).get("complete") is True:
            receipt.update(complete=True, **{stage: "failed"})
    save(args.output, receipt)
    return 0 if receipt["success"] else 1


def validation_receipts(directory, attempt):
    return [
        load(path, 4096)
        for path in Path(directory).glob("*/receipt.json")
        if not path.parent.name.startswith("repair-validation-")
        or path.parent.name.startswith(f"repair-validation-{attempt}-")
    ]


def verify_receipts(records, plan, proposal, tree=None):
    require(len(records) == len(TARGETS), "Validation receipts are missing.")
    require(
        {record.get("target") for record in records} == set(TARGETS),
        "Validation targets do not match.",
    )
    expected = {
        "sha": plan["sha"],
        "base": plan["base"],
        "proposal": digest(proposal),
        "attempt": plan.get("attempt", 1),
    }
    trees = {record.get("tree", "") for record in records}
    require(
        len(trees) == 1 and SHA.fullmatch(next(iter(trees))),
        "Validation trees do not match.",
    )
    if tree:
        require(trees == {tree}, "Validation does not match the exact repair tree.")
    original_targets = set(
        plan.get("baselineTargets", [record["target"] for record in plan["failures"]])
    )
    require(
        all(
            record.get("success") is not True
            or (
                record.get("baseline")
                == (
                    "passed" if record["target"] in original_targets else "not-required"
                )
                and record.get("repaired") == "passed"
            )
            for record in records
        ),
        "A successful receipt must include its required baseline and repaired build.",
    )
    require(
        all(
            record.get("complete") is True
            and all(record.get(key) == value for key, value in expected.items())
            for record in records
        ),
        "Validation evidence is incomplete or stale.",
    )


def revise(args):
    plan, proposal = load(args.plan), load(args.proposal, 32768)
    attempt = plan.get("attempt", 1)
    plan = {**plan, "attempt": attempt + 1, "eligible": False}
    try:
        require(attempt in (1, 2), "The three-attempt repair limit was reached.")
        require(
            bool(apply_proposal(plan, proposal)),
            "The previous proposal had no permitted repair.",
        )
        records = validation_receipts(args.validation, attempt)
        verify_receipts(records, {**plan, "attempt": attempt}, proposal)
        require(
            any(record.get("success") is False for record in records),
            "The previous repair already passed validation.",
        )
        original_targets = set(plan["baselineTargets"])
        require(
            all(
                record.get("baseline")
                == (
                    "passed" if record["target"] in original_targets else "not-required"
                )
                for record in records
            ),
            "A baseline failed. Automatic revision stopped.",
        )
        diagnostics = []
        for path in Path(args.validation).glob("*/repaired/diagnostic.json"):
            if path.parent.parent.name.startswith(f"repair-validation-{attempt}-"):
                diagnostics.append(load(path, 524288))
        failures, eligible = prepare_records(diagnostics, plan["sha"])
        require(
            eligible,
            "Validation found an incomplete or infrastructure failure. Automatic revision stopped.",
        )
        plan.update(
            eligible=True,
            historyFailures=[*plan.get("historyFailures", []), *plan["failures"]],
            failures=failures,
            previous={"proposal": proposal, "validation": records},
            reason=f"Repair attempt {attempt} failed. One bounded revision is allowed.",
        )
    except (ValueError, KeyError, TypeError, OSError) as error:
        plan["reason"] = f"Automatic revision stopped: {error}"
    save(args.output, plan)
    if output := os.environ.get("GITHUB_OUTPUT"):
        with open(output, "a") as stream:
            stream.write(f"eligible={str(plan['eligible']).lower()}\n")
    print(plan["reason"])


def bundle(args):
    plan, proposal = load(args.plan), load(args.proposal, 32768)
    changes, tree = apply_files(args.candidate, plan, proposal)
    receipts = validation_receipts(args.validation, plan.get("attempt", 1))
    verify_receipts(receipts, plan, proposal, tree)
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
    save(
        args.output,
        {
            **expected,
            "attempt": plan.get("attempt", 1),
            "files": changes,
            "targets": TARGETS,
        },
    )


def report(args):
    plan = load(args.plan)
    result = {
        "version": 1,
        "sha": plan["sha"],
        "base": plan["base"],
        "pr": plan["pr"],
        "admission": plan["reason"],
        "jobs": json.loads(os.environ.get("REPAIR_JOB_RESULTS", "{}")),
        "attempts": [],
        "selectedAttempt": None,
        "publication": {
            "status": "not-published",
            "commit": None,
            "reason": "No repair passed every publication check.",
        },
    }
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    Path(args.bundle).unlink(missing_ok=True)
    for attempt in range(1, 4):
        directory = (
            Path(args.evidence)
            / f"repair-proposal-{attempt}-{os.environ['RUN_ATTEMPT']}"
        )
        if not (directory / "plan.json").exists():
            continue
        context = load(directory / "plan.json")
        entry = {
            "attempt": attempt,
            "reason": context["reason"],
            "changes": [],
            "validation": [],
            "policy": {"allowed": False, "reason": "No proposal is available."},
        }
        result["attempts"].append(entry)
        try:
            require(
                all(
                    context[key] == plan[key]
                    for key in ("sha", "base", "pr", "files", "baselineTargets")
                )
                and context.get("attempt") == attempt,
                "The attempt source context changed.",
            )
            if (directory / "error.json").exists():
                entry["error"] = load(directory / "error.json", 8192)
            if not (directory / "proposal.json").exists():
                continue
            proposal = load(directory / "proposal.json", 32768)
            require(isinstance(proposal, dict), "The model proposal must be an object.")
            entry["proposal"] = proposal
            entry["changes"] = [
                {
                    "path": str(edit.get("path", ""))[:500],
                    "line": edit.get("line")
                    if type(edit.get("line")) is int
                    else "invalid",
                    "kind": str(edit.get("kind", ""))[:100],
                }
                for edit in (
                    proposal.get("edits", [])[:12]
                    if isinstance(proposal.get("edits"), list)
                    else []
                )
                if isinstance(edit, dict)
            ]
            entry["policy"]["reason"] = "The proposal failed the repair policy."
            changes = apply_proposal(context, proposal)
            entry["policy"] = {
                "allowed": bool(changes),
                "reason": "The repair policy passed."
                if changes
                else "The diagnosis requires owner review.",
            }
            entry["changes"] = [
                {"path": edit["path"], "line": edit["line"], "kind": edit["kind"]}
                for edit in proposal["edits"]
            ]
            patch_text = "".join(
                "".join(
                    difflib.unified_diff(
                        context["files"][path].splitlines(keepends=True),
                        text.splitlines(keepends=True),
                        fromfile=f"a/{path}",
                        tofile=f"b/{path}",
                    )
                )
                for path, text in changes.items()
            )
            entry["diff"] = patch_text
            if patch_text:
                (output.parent / f"attempt-{attempt}.patch").write_text(patch_text)
            receipts = validation_receipts(args.evidence, attempt)
            entry["validation"] = receipts
            if not changes or not receipts:
                continue
            verify_receipts(receipts, context, proposal)
            if not all(record.get("success") is True for record in receipts):
                continue
            require(
                result["selectedAttempt"] is None,
                "More than one repair attempt passed.",
            )
            bundle(
                argparse.Namespace(
                    candidate=args.candidate,
                    plan=directory / "plan.json",
                    proposal=directory / "proposal.json",
                    validation=args.evidence,
                    output=args.bundle,
                )
            )
            result["selectedAttempt"] = attempt
            result["publication"]["reason"] = (
                f"Repair attempt {attempt} passed every validation check. Publication has not started."
            )
        except (
            ValueError,
            KeyError,
            TypeError,
            OSError,
            subprocess.SubprocessError,
        ) as error:
            entry["error"] = {"stage": "verification", "message": str(error)}
            if result["selectedAttempt"] is not None:
                result["selectedAttempt"] = None
                Path(args.bundle).unlink(missing_ok=True)
                break
    save(output, result)


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
    command = commands.add_parser("revise")
    for name in ("plan", "proposal", "validation", "output"):
        command.add_argument(f"--{name}", required=True)
    command = commands.add_parser("report")
    for name in ("plan", "evidence", "candidate", "output", "bundle"):
        command.add_argument(f"--{name}", required=True)
    command = commands.add_parser("bundle")
    for name in ("candidate", "plan", "proposal", "validation", "output"):
        command.add_argument(f"--{name}", required=True)
    args = parser.parse_args()
    return {
        "prepare": prepare,
        "check": check,
        "validate": validate,
        "bundle": bundle,
        "revise": revise,
        "report": report,
    }[args.command](args)


if __name__ == "__main__":
    sys.exit(main())
