# Nix update and build runner

This runner supports the `update-flake` Pi prompt.
It uses Python's standard library and the installed Git and Nix commands.
It does not start agents, grant repair authority, activate systems, or enforce a security sandbox.

The parent admits work based on RAM, cgroup limits, swap, disk space, and unrelated builds.
The native workflow adapter schedules only that admitted work.
The runner handles command evidence and checkout bookkeeping.
It does not replace the parent resource check or completion review.

## Run files

Copy this directory and `.pi/workflows/update-flake.js` into a private directory outside the checkout.
Use the captured copies throughout the run.
Do not load changing prompt text as new authority.

The runner keeps an immutable initial snapshot.
It records later accepted snapshots separately.
Snapshots contain file hashes, symlink targets, semantic index entries, branch, and HEAD.
The runner excludes `secrets/` and does not follow file symlinks.
An unsafe symlink parent stops snapshot capture.

Commands use argument arrays without a shell.
Each command saves its argv, stdout, stderr, exit status, and elapsed time.
JSON writes are atomic.
A file lock serializes checkpoint changes.
Build commands run outside that lock so the parent can record decisions during a build.

## CLI reference

Run `python3 <captured-runner>/runner.py --run-dir <private-directory> <action>`.
The `--run-dir` option comes before the action.
Every command returns JSON.
Exit `0` means successful bookkeeping or completion.
Exit `2` means blocked, deferred, or awaiting input.
Inspect `verdict` before continuing.

| Action | Arguments | Purpose |
| --- | --- | --- |
| `init` | `--repo <path> --hostname <host> [--input-path <path> ...]` | Record the initial snapshot and update checkpoint |
| `status` | None | Read the checkpoint |
| `reconcile` | None | Record external changes without restoring files or the index |
| `accept-input-state` | `--evidence <reconciliation-file> --reason <text>` | Accept the exact diagnosed input state and invalidate the old plan |
| `own` | Approved repository-relative paths | Save the writer base and register one repair scope |
| `accept-owned` | None | Accept the inspected repair after scoped index checks |
| `merge` | `--base <file> --proposal <file> --current <file> --output <run-file>` | Make a three-way proposal without changing source files |
| `update` | None | Update inputs once and retain the actual command result |
| `plan` | `--graph <file> --toplevel <drv> --source <store-path> [--batch-size <count>]` | Normalize the saved graph, prune valid boundaries, register roots, and save batches |
| `build` | `--manifest <file>` | Build an admitted current-plan batch and record partial success |
| `final` | None | Check current-plan coverage and execute the full-system flake build |
| `checkpoint` | `--phase <phase> --result <json-file>` | Save a phase result reference |
| `recover` | `--failure <stable-key> [--settled] [--change-protocol]` | Select a bounded same-protocol continuation |
| `decision` | `--key <stable-key> --scope <json-file> [--status request\|asked\|resolved] [--resolution <text>]` | Deduplicate questions and record resolutions |

Resolve `AUTO` before `init`.
List configuration keys only after the update.
Supply paths that declare flake inputs through `--input-path`.
The runner always treats external `flake.lock` and generated `flake.nix` edits as input-state changes.

### Reconciliation

Non-conflicting edits, staging, and commits advance the accepted snapshot without a question.
Source changes set `checkTarget`.
The parent compares the actual target derivation at the next safe boundary.
An unchanged target can reuse its graph.
A changed target needs a new plan.

An unexpected owned-file change returns `ownedConflicts`.
An external input-state change returns `inputChanges`.
Both require diagnosis, not automatic user interruption.
Ask only if the diagnosis finds overlapping edits or a choice between update states.
After diagnosis, the parent selects the update state with `accept-input-state`.
Pass the exact reconciliation evidence and record the selection reason.
The command rejects a stale baseline or any checkout change after inspection.
It accepts only input paths, not other pending repair changes.
It retains the inspection and initial snapshot, then invalidates the old plan.
A successful update checkpoint remains complete, so continuation does not update inputs again.

The parent calls `own` before granting approved write authority.
The returned `writerBaseFiles` references preserve the pre-edit bytes.
After the writer stops, the parent inspects the diff and calls `accept-owned`.
That command rejects staging inside the active writer scope.
Unrelated user staging remains untouched.

For disjoint edits, `merge` writes only a run-directory proposal.
The writer must verify the current file before applying the inspected proposal.
A merge conflict preserves all versions and returns `needs_input`.

### Planning and builds

The planner evaluates the selected host and saves its recursive derivation graph.
Pass that exact graph and captured flake source to `plan`.
The runner supports legacy `inputDrvs` and versioned `inputs.drvs` graphs.
For required version-4 fixed outputs, it queries the exact output binding through Nix.
It does not query fixed outputs below pruned boundaries.
It rejects incomplete graphs, unresolved content-addressed paths, dynamic outputs, and cycles.

The runner checks required outputs through Nix before expanding prerequisites.
A valid boundary covers its build prerequisites.
Only required output names enter manifests.
The toplevel never enters a component batch.
Dependency order and shared ownership come from the graph.
The default batch size is 32 targets.

The parent checks the actual download/build plan before dispatch.
Treat `heavy` as a hint, not proof of low memory use for other batches.
Use exclusive admission for unresolved large compiles.
The runner uses `--keep-going` so independent outputs can complete within a failed batch.
It roots and reports verified partial success.

Roots use supported Nix registration commands.
Existing derivations use `nix-instantiate --add-root` without output realization.
Valid non-derivation outputs use `nix-store --realise --add-root`.
The helper verifies the indirect registration through filesystem links.
It does not invoke GC inspection.

The parent runs focused validation and the required review before `final`.
The final command checks current-plan batch results and output validity.
It compares the actual toplevel derivation before building.
It checks the resulting output against the accepted plan.
Target drift returns `deferred`, not success from stale coverage.

### Continuations and decisions

A successful `update` returns its saved result on later calls.
A running or failed update returns `blocked`.
Inspect its command evidence before changing that state.
Do not clear the checkpoint and repeat the update.

A recovery requires settled owned processes and the same protocol.
The runner permits three recoveries per stable failure key.
It does not change models, providers, repair authority, or execution mode.

Use `question` only.
Request a decision with its exact scope.
Mark it `asked` before posting the question.
Record the answer with `resolved` and `--resolution`.
The runner suppresses another question for an asked or resolved scope.
It rejects replacing a pending scope.

## Native workflow adapter

Launch the captured `update-flake.js` with the same `missionId` on each continuation.
Its arguments are `steps` and `concurrency`, limited to 64 steps and one or two children.
Each step has `key`, `label`, `task`, `model`, `output`, `deps`, and `exclusive`.
Use brief-file references in `task`.

The adapter saves JSON-safe completion records in mission state.
It reuses a complete record only when the entire step contract matches.
Use current-plan keys for builds.
Keep the update key and contract stable.
The runner's update checkpoint remains the second protection against repeated updates.

The adapter continues independent steps after a target blocker.
It drains active children before returning after an infrastructure failure.
Children return only `verdict` and `evidenceRef`.
Store graphs, manifests, and detailed reports in run files.

Repository-wide index acceptance is intentionally absent.
The parent must run the scoped runner checks and inspect the repair diff.
No helper may stage or unstage source files.

## Validation

1. Run `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s scripts/nix-update-build -p 'test_*.py' -v`.
2. Run `node --test scripts/nix-update-build/test_workflow.mjs`.
3. Validate `.pi/workflows/update-flake.js` with the native subagent `validate` action.

Tests use temporary Git repositories and fake Nix operations.
They do not update inputs, compile packages, activate a host, or access account services.
