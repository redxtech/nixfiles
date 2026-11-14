# flake update remediation reference

reference for the conditional repair jobs in `.github/workflows/update-flake.yml`.

## activation

repair admission requires a manual update workflow on `main`, an open update PR, and a failed build job.
the initial update must change only `flake.lock` relative to the workflow source commit.
all eight targets must have complete diagnostics for the same build SHA.
missing diagnostics, cancelled jobs, resource failures, network failures, and upload-only failures do not permit automatic edits.

## jobs

| job | contract |
| --- | --- |
| `repair-plan` | separates nix failures from upload failures and captures an immutable source snapshot |
| `repair-diagnose` | proposes the first bounded repair through quasar and checks its policy |
| `repair-validate` | builds all eight repaired targets on fresh runners without model or upload credentials |
| `repair-diagnose-2`, `repair-diagnose-3` | revise a failed repair using its complete validation evidence |
| `repair-validate-2`, `repair-validate-3` | independently validate each revised proposal |
| `repair-publish` | reconstructs the exact validated tree, updates the existing PR, and uploads an action report |

originally failing targets must also build at the pre-update commit during each validation attempt.
a failed baseline prevents publication and further automatic attempts.
incomplete validation or an infrastructure failure also stops automatic revision.
a policy rejection, report-only diagnosis, or model error ends the repair path without another model attempt.
the policy rejects a repeated proposal that produces the same files.

all proposals describe complete changes relative to the original failed update commit.
later proposals do not inherit an unverified working tree.
publication requires one successful attempt, not a combination of receipts from different attempts.

## model access

| setting | value |
| --- | --- |
| runtime | `@earendil-works/pi-coding-agent` at `1.4.0`, with a committed npm lockfile |
| API | OpenAI Responses at `https://ai-api.colobus-pirate.ts.net/v1` |
| model | `gpt-6.1-sol`, with no fallback |
| credential | repository secret `CLIPROXYAPI_REPAIR_KEY`, supplied by the owner |
| federation | repository variables `TS_REPAIR_CLIENT_ID` and `TS_REPAIR_AUDIENCE` |
| tailnet identity | ephemeral `tag:ci-repair`, restricted to `svc:ai-api` on TCP 443 |

CLIProxyAPI forwards requests to its configured upstream provider.
repository source excerpts and build logs can therefore reach that provider.
the workflow does not use the CLIProxyAPI management API or SSH.
model errors retain their HTTP status and error message, with the repair credential and authorization headers removed.

## automatic edits

| kind | permitted form |
| --- | --- |
| `option-rename` | complete `programs.*` or `xdg.*` assignment key, with the value unchanged |
| `package-rename` | `pkgs.*` attribute reference |
| `library-rename` | `lib.*` attribute reference |
| `package-compatibility` | complete literal compiler-flag or `postPatch` binding in an existing local package recipe |
| `source-patch` | text replacement in an existing patch referenced by its local package recipe |

a rename requires a failed-log excerpt that explicitly suggests the replacement and names both final identifiers.
rename candidates remain existing nix files under `modules/features/` and `packages/`.
`policy.py` excludes server features, protected paths, and protected identifiers.
feature activation, values, strings, and comments cannot change through a rename.

package compatibility edits are limited to existing files under `packages/`.
the failed log must identify that package and contain an exact compatibility-error excerpt.
one complete-line text block can change per compatibility file.
each block is at most 8,192 characters, with at most 80 changed lines.

recipe bindings are limited to `NIX_CFLAGS_COMPILE`, `CFLAGS`, `CXXFLAGS`, `cmakeFlags`, `mesonFlags`, `configureFlags`, `makeFlags`, and `postPatch`.
these bindings must retain their names and use literal strings or lists of literal strings without interpolation.
source patches must retain their file targets and number of hunks.
the policy checks unified-diff syntax and hunk line counts.

source identities, hashes, versions, dependencies, patch removal, disabled checks, weakened assertions, and security-sensitive changes remain report-only.
the policy rejects new files and input rollbacks.
third-party source absent from the snapshot cannot be repaired automatically.
policy checks and successful builds do not prove semantic equivalence.
the model must explain why each permitted repair preserves intended behavior.

## diagnostic context

diagnostics retain the output start, primary failure, and final output within a 64 KiB text limit.
the initial model prompt contains failure-focused excerpts instead of only the final log tail.
the snapshot tools can read the retained logs through virtual `diagnostics/` paths.
prior failed logs remain available as evidence during revision.
build and validation artifacts also include bounded raw phase logs.

## execution limits

| limit | value |
| --- | --- |
| repair attempts | three per workflow attempt |
| model duration | ten minutes per attempt |
| model turns | 24 per attempt |
| reported model tokens | 250,000 per attempt, checked after each response |
| snapshot tool calls | 40 successful result attempts per model session |
| edits | 12, across at most three existing files |
| proposal JSON | 32 KiB |
| raw diagnostic log | 16 MiB per phase |
| validation parallelism | two runners |
| validation duration | 360 minutes per target per attempt, including its required baseline |
| artifact retention | 14 days |

the final in-flight response can exceed the token limit.
source reads return bounded ranges from an in-memory snapshot.
no shell, filesystem write, web, MCP, project extension, or ambient configuration tool is available to the model.
the snapshot excludes files under `secrets/`.
artifact names include both the repair attempt and the workflow attempt.
failed-jobs-only reruns do not reconstruct artifacts from an earlier workflow attempt.

## action reports

| output | contents |
| --- | --- |
| managed PR description section | each attempt, diagnosis, policy result, changed paths, bounded diff, validation results, and publication outcome |
| bot comment | the same report, keyed by workflow run and workflow attempt |
| `repair-report-<workflow-attempt>/report.json` | structured actions, proposals, exact diffs, receipts, publication state, commit SHA, and reporting errors |
| `repair-report-<workflow-attempt>/report.md` | human-readable report with complete diffs |
| `repair-report-<workflow-attempt>/attempt-<repair-attempt>.patch` | exact proposed diff for each policy-approved attempt, including attempts that did not pass validation |

the report distinguishes proposed changes from published changes.
the report marks only the selected, fully validated attempt as published.
a blocked or failed publication still writes its local report for the final artifact upload.
a reporting failure after a successful branch update retains the published commit in the artifact.
the report marks an uncertain branch-update response as uncertain.
it does not claim that publication failed.
owner text outside the managed PR description section is preserved.
a stale PR prevents description and branch changes, but the artifact records the block.

## publication

publication requires eight complete successful receipts with the same source SHA, baseline SHA, proposal digest, attempt, and git tree.
the publisher reapplies the repair policy before it constructs that tree.
the github-created tree must match the validated tree exactly.

branch updates are non-force pushes with the failed update commit as their only parent.
a changed PR head or base stops publication.
`update-flake / repair-validation` applies to the new repair commit.
it reports target builds, not cache uploads.
the original `update-flake / validation` result remains attached to the initial update commit.
the original workflow remains failed when its original build jobs failed.
validation does not rely on another workflow starting from the bot push.

there is no automatic merge, deployment, input rollback, cache upload, or host activation in the repair path.
