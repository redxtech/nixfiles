from __future__ import annotations

import argparse
import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from checkout import allowed_path, file_record, git, merge_proposal, reconcile, snapshot
from execution import Nix
from graph import normalize, plan
from runner import dispatch, initialize, update
from state import (
    RunnerError,
    locked_run,
    read_json,
    recovery,
    request_decision,
    write_json,
)


def record(
    name: str, dependencies: dict | None = None, outputs: tuple[str, ...] = ("out",)
) -> dict:
    return {
        "system": "x86_64-linux",
        "outputs": {output: {"path": name + "-" + output} for output in outputs},
        "inputs": {"drvs": dependencies or {}},
    }


class CheckoutTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name) / "repo"
        self.repo.mkdir()
        git(self.repo, "init", "-q")
        git(self.repo, "config", "user.email", "fixture@example.invalid")
        git(self.repo, "config", "user.name", "Fixture")
        git(self.repo, "config", "core.hooksPath", "/dev/null")
        for name in ("repair.nix", "user.toml", "flake.lock"):
            (self.repo / name).write_text("original\n")
        (self.repo / "secrets").mkdir()
        (self.repo / "secrets/private").write_text("do not read")
        git(
            self.repo,
            "add",
            "--",
            "repair.nix",
            "user.toml",
            "flake.lock",
            "secrets/private",
        )
        git(self.repo, "commit", "-qm", "fixture")
        self.directory = Path(self.temporary.name) / "run"
        initialize(self.repo, self.directory, "bastion", [])

    def test_unrelated_edit_stage_commit_never_requests_input(self) -> None:
        original_index = snapshot(self.repo)["index"]["repair.nix"]
        baseline = snapshot(self.repo)
        for operation in ("edit", "stage", "commit"):
            if operation == "edit":
                (self.repo / "user.toml").write_text("external\n")
            elif operation == "stage":
                git(self.repo, "add", "--", "user.toml")
            else:
                git(self.repo, "commit", "-qm", "external")
            current = snapshot(self.repo)
            result = reconcile(baseline, current, {}, [])
            self.assertEqual(result["verdict"], "complete")
            self.assertNotIn("ask", result)
            self.assertEqual(current["index"]["repair.nix"], original_index)
            baseline = current

    def test_prompt_intent_to_add_is_external(self) -> None:
        baseline = snapshot(self.repo)
        (self.repo / "prompt.md").write_text("new")
        git(self.repo, "add", "-N", "--", "prompt.md")
        result = reconcile(baseline, snapshot(self.repo), {}, [])
        self.assertEqual(result["verdict"], "complete")
        self.assertEqual(result["externalPaths"], ["prompt.md"])
        self.assertTrue(result["checkTarget"])

    def test_owned_overlap_only_blocks_that_path(self) -> None:
        baseline = snapshot(self.repo)
        (self.repo / "repair.nix").write_text("external")
        (self.repo / "user.toml").write_text("unrelated")
        result = reconcile(
            baseline,
            snapshot(self.repo),
            {"repair.nix": baseline["files"]["repair.nix"]},
            [],
        )
        self.assertEqual(result["ownedConflicts"], ["repair.nix"])
        self.assertEqual(result["externalPaths"], ["user.toml"])

    def test_input_change_blocks_selection_not_read_only_diagnosis(self) -> None:
        baseline = snapshot(self.repo)
        (self.repo / "flake.lock").write_text("external")
        result = reconcile(baseline, snapshot(self.repo), {}, [])
        self.assertEqual(result["inputChanges"], ["flake.lock"])
        self.assertEqual(result["verdict"], "blocked")

    def test_secrets_are_not_read(self) -> None:
        original = Path.read_bytes

        def guarded(path: Path) -> bytes:
            if "secrets" in path.parts:
                self.fail("a secret was read")
            return original(path)

        with patch.object(Path, "read_bytes", guarded):
            self.assertNotIn("secrets/private", snapshot(self.repo)["files"])

    def test_symlinks_are_not_followed(self) -> None:
        path = self.repo / "link"
        path.symlink_to(self.repo / "secrets/private")
        self.assertEqual(file_record(self.repo, "link")["kind"], "symlink")
        directory = self.repo / "unsafe"
        directory.symlink_to(self.repo / "secrets", target_is_directory=True)
        with self.assertRaises(RunnerError):
            file_record(self.repo, "unsafe/private")

    def test_path_traversal_and_private_checkout_run_rejected(self) -> None:
        for name in ("secrets/a", "../a", "/tmp/a", ".git/index"):
            self.assertFalse(allowed_path(name))
        with self.assertRaises(RunnerError):
            initialize(self.repo, self.repo / "run", "bastion", [])

    def accept_input_args(self, evidence: str) -> argparse.Namespace:
        return argparse.Namespace(
            run_dir=self.directory,
            action="accept-input-state",
            evidence=Path(evidence),
            reason="Exact-source diagnosis selected the inspected user lock.",
        )

    def test_diagnosed_input_state_can_continue_without_losing_evidence(self) -> None:
        original = read_json(self.directory / "state.json")
        with locked_run(self.directory) as state:
            state["update"] = {"status": "complete", "command": {"exit": 0}}
            state["planRef"] = "obsolete-plan"
        (self.repo / "flake.lock").write_text("chosen external lock")
        blocked = dispatch(
            argparse.Namespace(run_dir=self.directory, action="reconcile")
        )
        self.assertEqual(blocked["verdict"], "blocked")
        result = dispatch(self.accept_input_args(blocked["evidenceRef"]))
        self.assertEqual(result["verdict"], "complete")
        self.assertEqual(
            dispatch(argparse.Namespace(run_dir=self.directory, action="reconcile"))[
                "verdict"
            ],
            "complete",
        )
        current = read_json(self.directory / "state.json")
        self.assertEqual(current["initialRef"], original["initialRef"])
        self.assertTrue(Path(blocked["evidenceRef"]).exists())
        self.assertNotIn("planRef", current)
        self.assertEqual(current["phase"], "plan")
        with patch.object(Nix, "command") as command:
            self.assertTrue(update(self.directory)["reused"])
            command.assert_not_called()

    def test_input_acceptance_handles_a_lock_owned_by_completed_update(self) -> None:
        with locked_run(self.directory) as state:
            state["owned"]["flake.lock"] = file_record(self.repo, "flake.lock")
            state["update"]["status"] = "complete"
        (self.repo / "flake.lock").write_text("external replacement")
        blocked = dispatch(
            argparse.Namespace(run_dir=self.directory, action="reconcile")
        )
        self.assertEqual(blocked["ownedConflicts"], ["flake.lock"])
        result = dispatch(self.accept_input_args(blocked["evidenceRef"]))
        self.assertEqual(result["verdict"], "complete")
        self.assertEqual(
            dispatch(argparse.Namespace(run_dir=self.directory, action="reconcile"))[
                "verdict"
            ],
            "complete",
        )

    def test_stale_input_inspection_cannot_be_accepted(self) -> None:
        (self.repo / "flake.lock").write_text("inspected")
        blocked = dispatch(
            argparse.Namespace(run_dir=self.directory, action="reconcile")
        )
        (self.repo / "flake.lock").write_text("changed again")
        original = (self.directory / "state.json").read_bytes()
        with self.assertRaises(RunnerError):
            dispatch(self.accept_input_args(blocked["evidenceRef"]))
        self.assertEqual((self.directory / "state.json").read_bytes(), original)

    def test_input_acceptance_does_not_accept_unrelated_owned_changes(self) -> None:
        dispatch(
            argparse.Namespace(
                run_dir=self.directory, action="own", paths=["repair.nix"]
            )
        )
        (self.repo / "repair.nix").write_text("unaccepted repair")
        (self.repo / "flake.lock").write_text("chosen input")
        blocked = dispatch(
            argparse.Namespace(run_dir=self.directory, action="reconcile")
        )
        dispatch(self.accept_input_args(blocked["evidenceRef"]))
        still_blocked = dispatch(
            argparse.Namespace(run_dir=self.directory, action="reconcile")
        )
        self.assertEqual(still_blocked["ownedConflicts"], ["repair.nix"])
        self.assertEqual(still_blocked["inputChanges"], [])
        self.assertEqual(
            dispatch(argparse.Namespace(run_dir=self.directory, action="accept-owned"))[
                "verdict"
            ],
            "complete",
        )

    def test_declared_input_and_generated_flake_can_be_accepted(self) -> None:
        with locked_run(self.directory) as state:
            state["inputPaths"] = ["repair.nix"]
        (self.repo / "repair.nix").write_text("updated declaration")
        (self.repo / "flake.nix").write_text("generated declaration")
        blocked = dispatch(
            argparse.Namespace(run_dir=self.directory, action="reconcile")
        )
        result = dispatch(self.accept_input_args(blocked["evidenceRef"]))
        self.assertEqual(result["acceptedInputPaths"], ["flake.nix", "repair.nix"])
        self.assertEqual(
            dispatch(argparse.Namespace(run_dir=self.directory, action="reconcile"))[
                "verdict"
            ],
            "complete",
        )

    def test_input_selection_does_not_hide_staging_inside_writer_scope(self) -> None:
        with locked_run(self.directory) as state:
            state["inputPaths"] = ["repair.nix"]
        dispatch(
            argparse.Namespace(
                run_dir=self.directory, action="own", paths=["repair.nix"]
            )
        )
        (self.repo / "repair.nix").write_text("changed input declaration")
        git(self.repo, "add", "--", "repair.nix")
        blocked = dispatch(
            argparse.Namespace(run_dir=self.directory, action="reconcile")
        )
        dispatch(self.accept_input_args(blocked["evidenceRef"]))
        rejected = dispatch(
            argparse.Namespace(run_dir=self.directory, action="accept-owned")
        )
        self.assertEqual(rejected["ownedIndexChanges"], ["repair.nix"])
        self.assertEqual(rejected["verdict"], "blocked")

    def test_input_acceptance_rejects_evidence_without_input_changes(self) -> None:
        clean = dispatch(argparse.Namespace(run_dir=self.directory, action="reconcile"))
        with self.assertRaises(RunnerError):
            dispatch(self.accept_input_args(clean["evidenceRef"]))

    def test_parent_accepts_only_active_owned_repair(self) -> None:
        args = argparse.Namespace(
            run_dir=self.directory, action="own", paths=["repair.nix"]
        )
        dispatch(args)
        (self.repo / "repair.nix").write_text("approved repair")
        (self.repo / "flake.lock").write_text("unapproved")
        result = dispatch(
            argparse.Namespace(run_dir=self.directory, action="accept-owned")
        )
        self.assertEqual(result["verdict"], "blocked")

    def test_writer_cannot_stage_its_repair(self) -> None:
        dispatch(
            argparse.Namespace(
                run_dir=self.directory, action="own", paths=["repair.nix"]
            )
        )
        (self.repo / "repair.nix").write_text("repair")
        git(self.repo, "add", "--", "repair.nix")
        result = dispatch(
            argparse.Namespace(run_dir=self.directory, action="accept-owned")
        )
        self.assertEqual(result["ownedIndexChanges"], ["repair.nix"])
        self.assertEqual(result["verdict"], "blocked")

    def test_disjoint_merge_preserves_both_edits_without_touching_checkout(
        self,
    ) -> None:
        base = self.directory / "base"
        proposal = self.directory / "proposal"
        current = self.directory / "current"
        output = self.directory / "merged"
        base.write_text("a\nb\nc\nd\ne\n")
        proposal.write_text("repair\nb\nc\nd\ne\n")
        current.write_text("a\nb\nc\nd\nuser\n")
        result = merge_proposal(base, proposal, current, output)
        self.assertEqual(result["verdict"], "complete")
        self.assertEqual(output.read_text(), "repair\nb\nc\nd\nuser\n")
        self.assertEqual(current.read_text(), "a\nb\nc\nd\nuser\n")

    def test_overlapping_merge_needs_input_and_keeps_all_versions(self) -> None:
        paths = [
            self.directory / name for name in ("base", "proposal", "current", "merged")
        ]
        for path, content in zip(paths, ("base\n", "repair\n", "user\n")):
            path.write_text(content)
        self.assertEqual(merge_proposal(*paths)["verdict"], "needs_input")
        self.assertFalse(paths[3].exists())

    def test_update_success_is_not_repeated_on_resume(self) -> None:
        calls = []

        def fake_command(nix: Nix, argv: list[str], label: str) -> dict:
            calls.append(argv)
            (self.repo / "flake.lock").write_text("updated")
            return {"exit": 0, "stdoutRef": "fixture", "stderrRef": "fixture"}

        with patch.object(Nix, "command", fake_command):
            self.assertEqual(update(self.directory)["verdict"], "complete")
            self.assertTrue(update(self.directory)["reused"])
        self.assertEqual(len(calls), 1)
        self.assertEqual(
            calls[0], ["nix", "flake", "update", "--max-jobs", "1", "--cores", "1"]
        )

    def test_unknown_update_outcome_never_retries(self) -> None:
        with locked_run(self.directory) as state:
            state["update"]["status"] = "running"
        with patch.object(Nix, "command") as command:
            self.assertEqual(update(self.directory)["verdict"], "blocked")
            command.assert_not_called()

    def test_checkpoint_original_is_immutable(self) -> None:
        before = read_json(self.directory / "state.json")
        original = Path(before["initialRef"]).read_bytes()
        (self.repo / "user.toml").write_text("external")
        result = dispatch(
            argparse.Namespace(run_dir=self.directory, action="reconcile")
        )
        self.assertEqual(result["verdict"], "complete")
        self.assertEqual(Path(before["initialRef"]).read_bytes(), original)


class StateTests(unittest.TestCase):
    def test_one_question_per_exact_scope(self) -> None:
        state = {}
        first = request_decision(state, "honcho-migration", {"paths": ["repair.nix"]})
        self.assertTrue(first["ask"])
        state["decisions"]["honcho-migration"]["asked"] = True
        self.assertFalse(
            request_decision(state, "honcho-migration", {"paths": ["repair.nix"]})[
                "ask"
            ]
        )
        state["decisions"]["honcho-migration"]["status"] = "resolved"
        self.assertFalse(
            request_decision(state, "honcho-migration", {"paths": ["repair.nix"]})[
                "ask"
            ]
        )

    def test_pending_scope_cannot_be_replaced(self) -> None:
        state = {}
        request_decision(state, "change", {"path": "a"})
        with self.assertRaises(RunnerError):
            request_decision(state, "change", {"path": "b"})

    def test_same_protocol_recovery_is_bounded_and_does_not_reset_update(self) -> None:
        state = {"update": {"status": "complete"}}
        self.assertEqual(
            recovery(state, "emit-undefined", False, True), "reconcile_processes"
        )
        self.assertEqual(recovery(state, "emit-undefined", True, False), "needs_input")
        for _ in range(3):
            self.assertEqual(
                recovery(state, "emit-undefined", True, True), "resume_checkpoint"
            )
        self.assertEqual(recovery(state, "emit-undefined", True, True), "blocked")
        self.assertEqual(state["update"]["status"], "complete")

    def test_non_json_checkpoint_does_not_replace_previous_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "state.json"
            write_json(path, {"phase": "plan"})
            with self.assertRaises(ValueError):
                write_json(path, {"value": float("nan")})
            self.assertEqual(read_json(path), {"phase": "plan"})


class GraphTests(unittest.TestCase):
    def graph(self) -> dict:
        return normalize(
            {
                "derivations": {
                    "root.drv": record(
                        "root",
                        {"a.drv": {"outputs": ["out"]}, "b.drv": {"outputs": ["out"]}},
                    ),
                    "a.drv": record(
                        "a", {"shared.drv": {"outputs": ["out"]}}, ("out", "doc")
                    ),
                    "b.drv": record("b", {"shared.drv": {"outputs": ["out"]}}),
                    "shared.drv": record("shared"),
                },
                "version": 3,
            }
        )

    def test_required_outputs_deduplicated_and_top_level_excluded(self) -> None:
        result = plan(self.graph(), "root.drv", lambda paths: set(), 2)
        targets = [target for batch in result["batches"] for target in batch["targets"]]
        self.assertEqual(len(targets), 3)
        self.assertEqual({target["output"] for target in targets}, {"out"})
        self.assertNotIn("/nix/store/root.drv", {target["drv"] for target in targets})

    def test_valid_boundaries_prune_historical_prerequisites(self) -> None:
        seen = []

        def valid(paths: list[str]) -> set[str]:
            seen.extend(paths)
            return set(paths)

        result = plan(self.graph(), "root.drv", valid)
        self.assertEqual(result["batches"], [])
        self.assertNotIn("/nix/store/shared-out", seen)
        self.assertEqual(result["requiredCount"], 2)

    def test_batch_dependencies_and_shared_owner(self) -> None:
        result = plan(self.graph(), "root.drv", lambda paths: set(), 1)
        self.assertEqual(
            result["batches"][0]["targets"][0]["drv"], "/nix/store/shared.drv"
        )
        self.assertEqual(result["batches"][1]["deps"], ["batch-0"])
        self.assertEqual(result["batches"][2]["deps"], ["batch-0"])

    def test_version_four_fixed_output_is_resolved_only_when_required(self) -> None:
        fixed = {
            "system": "x86_64-linux",
            "outputs": {"out": {"hash": "sha256-fixture", "method": "flat"}},
            "inputs": {"drvs": {}},
        }
        graph = normalize(
            {
                "derivations": {
                    "root.drv": record("root", {"fixed.drv": {"outputs": ["out"]}}),
                    "fixed.drv": fixed,
                    "unused.drv": fixed,
                },
                "version": 4,
            }
        )
        queries = []

        def resolve(drv: str, output: str) -> str:
            queries.append((drv, output))
            return "/nix/store/fixed-out"

        result = plan(
            graph, "root.drv", lambda paths: set(paths), resolve_output=resolve
        )
        self.assertEqual(queries, [("/nix/store/fixed.drv", "out")])
        self.assertEqual(result["boundaries"], ["/nix/store/fixed-out"])

    def test_legacy_format(self) -> None:
        graph = normalize(
            {
                "/nix/store/root.drv": {
                    "system": "x86_64-linux",
                    "outputs": {"out": {"path": "/nix/store/root-out"}},
                    "inputDrvs": {"/nix/store/a.drv": ["out"]},
                },
                "/nix/store/a.drv": {
                    "system": "x86_64-linux",
                    "outputs": {"out": {"path": "/nix/store/a-out"}},
                    "inputDrvs": {},
                },
            }
        )
        self.assertEqual(
            plan(graph, "root.drv", lambda paths: set())["requiredCount"], 1
        )

    def test_dynamic_and_incomplete_graph_fail_closed(self) -> None:
        with self.assertRaises(RunnerError):
            normalize(
                {
                    "a.drv": record(
                        "a",
                        {"b.drv": {"outputs": ["out"], "dynamicOutputs": {"out": {}}}},
                    )
                }
            )
        graph = self.graph()
        del graph["/nix/store/shared.drv"]
        with self.assertRaises(RunnerError):
            plan(graph, "root.drv", lambda paths: set())

    def test_cycles_are_rejected(self) -> None:
        graph = normalize(
            {
                "root.drv": record("root", {"a.drv": {"outputs": ["out"]}}),
                "a.drv": record("a", {"b.drv": {"outputs": ["out"]}}),
                "b.drv": record("b", {"a.drv": {"outputs": ["out"]}}),
            }
        )
        with self.assertRaises(RunnerError):
            plan(graph, "root.drv", lambda paths: set())

    def test_cache_pruning_does_not_traverse_33000_historical_nodes(self) -> None:
        records = {
            "root.drv": record("root", {"cached.drv": {"outputs": ["out"]}}),
            "cached.drv": record("cached"),
        }
        records.update(
            {str(index) + ".drv": record(str(index)) for index in range(33000)}
        )
        result = plan(
            normalize({"derivations": records}), "root.drv", lambda paths: set(paths)
        )
        self.assertEqual(result["requiredCount"], 1)
        self.assertEqual(result["batches"], [])


class ExecutionTests(unittest.TestCase):
    def test_final_target_drift_does_not_build(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            stdout = directory / "drv"
            stdout.write_text("/nix/store/new.drv")
            nix = Nix(directory, directory)
            with patch.object(
                nix, "command", return_value={"exit": 0, "stdoutRef": str(stdout)}
            ) as command:
                result = nix.final(
                    "bastion",
                    {
                        "identity": {
                            "toplevel": "/nix/store/old.drv",
                            "output": "/nix/store/old-out",
                        }
                    },
                )
            self.assertEqual(result["verdict"], "deferred")
            self.assertEqual(command.call_count, 1)
            self.assertEqual(command.call_args.args[0][1], "eval")

    def test_final_build_uses_selected_flake_and_checks_actual_output(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            stdout = directory / "drv"
            stdout.write_text("/nix/store/root.drv")
            nix = Nix(directory, directory)
            calls = []

            def command(argv: list[str], label: str) -> dict:
                calls.append(argv)
                if argv[1] == "build":
                    Path(argv[argv.index("--out-link") + 1]).symlink_to(
                        "/nix/store/root-out"
                    )
                return {"exit": 0, "stdoutRef": str(stdout)}

            with (
                patch.object(nix, "command", side_effect=command),
                patch.object(nix, "root", return_value="registered"),
            ):
                result = nix.final(
                    "bastion",
                    {
                        "identity": {
                            "toplevel": "/nix/store/root.drv",
                            "output": "/nix/store/root-out",
                        }
                    },
                )
            self.assertEqual(result["verdict"], "complete")
            self.assertEqual(
                calls[1][2],
                '.#nixosConfigurations."bastion".config.system.build.toplevel',
            )
            self.assertIn("--max-jobs", calls[1])
            self.assertIn("--no-update-lock-file", calls[1])

    def test_source_change_after_build_cannot_claim_latest_target_success(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            old = directory / "old"
            old.write_text("/nix/store/root.drv")
            changed = directory / "changed"
            changed.write_text("/nix/store/new.drv")
            nix = Nix(directory, directory)

            def command(argv: list[str], label: str) -> dict:
                if argv[1] == "build":
                    Path(argv[argv.index("--out-link") + 1]).symlink_to(
                        "/nix/store/root-out"
                    )
                return {
                    "exit": 0,
                    "stdoutRef": str(changed if label == "final-postflight" else old),
                }

            with (
                patch.object(nix, "command", side_effect=command),
                patch.object(nix, "root", return_value="registered"),
            ):
                result = nix.final(
                    "bastion",
                    {
                        "identity": {
                            "toplevel": "/nix/store/root.drv",
                            "output": "/nix/store/root-out",
                        }
                    },
                )
            self.assertEqual(result["verdict"], "deferred")
            self.assertEqual(result["reason"], "target_changed_after_build")

    def test_real_command_exit_is_captured_without_pipeline(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            nix = Nix(Path(directory), Path(directory))
            result = nix.command(["sh", "-c", "printf failure >&2; exit 7"], "fixture")
            self.assertEqual(result["exit"], 7)
            self.assertEqual(Path(result["stderrRef"]).read_text(), "failure")

    def test_partial_success_is_rooted_and_failed_outputs_retained(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            nix = Nix(Path(directory), Path(directory))
            targets = [
                {
                    "drv": "/nix/store/a.drv",
                    "output": "out",
                    "path": "/nix/store/a-out",
                },
                {
                    "drv": "/nix/store/b.drv",
                    "output": "out",
                    "path": "/nix/store/b-out",
                },
            ]
            with (
                patch.object(nix, "valid", side_effect=[set(), {"/nix/store/a-out"}]),
                patch.object(nix, "root", return_value="fixture-root"),
                patch.object(nix, "command", return_value={"exit": 1}) as command,
            ):
                result = nix.build(targets, "batch")
            self.assertEqual(result["verdict"], "blocked")
            self.assertEqual(result["completedPaths"], ["/nix/store/a-out"])
            self.assertEqual(result["unresolvedPaths"], ["/nix/store/b-out"])
            argv = command.call_args.args[0]
            self.assertIn("--keep-going", argv)
            self.assertIn("/nix/store/a.drv^out", argv)
            self.assertIn("--no-update-lock-file", argv)

    def test_derivation_root_never_realizes_or_collects(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            auto = directory / "state" / "gcroots" / "auto"
            auto.mkdir(parents=True)
            nix = Nix(directory, directory)
            path = "/nix/store/a.drv"

            def command(argv: list[str], label: str) -> dict:
                root = Path(argv[argv.index("--add-root") + 1])
                root.symlink_to(path)
                (auto / "registered").symlink_to(root)
                return {"exit": 0}

            with (
                patch.dict(os.environ, {"NIX_STATE_DIR": str(directory / "state")}),
                patch.object(nix, "valid", return_value={path}),
                patch.object(nix, "command", side_effect=command) as called,
            ):
                root = nix.root(path)
            argv = called.call_args.args[0]
            self.assertEqual(argv[0], "nix-instantiate")
            self.assertNotIn("--realise", argv)
            self.assertNotIn("--gc", argv)
            self.assertEqual(os.readlink(root), path)


if __name__ == "__main__":
    unittest.main()
