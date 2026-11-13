# flake update repair reference

reference for the conditional repair jobs in `.github/workflows/update-flake.yml`.

## activation

repair admission requires a manual update workflow on `main`, an open update PR, and a failed build job.
the initial update must change only `flake.lock` relative to the workflow source commit.
all eight targets must have complete diagnostics for the same build SHA.
missing diagnostics, cancelled jobs, resource failures, network failures, and upload-only failures do not permit automatic edits.

## jobs

| job | contract |
| --- | --- |
| `repair-plan` | separates Nix failures from upload failures and captures an immutable source snapshot |
| `repair-diagnose` | calls `gpt-6.1-sol` through quasar and checks the proposed renames |
| `repair-validate` | builds all eight repaired targets on fresh runners without model or upload credentials |
| `repair-publish` | reconstructs the validated tree, commits to the existing update branch, and updates the PR description |

originally failing targets must also build at the pre-update commit.
a failed baseline prevents publication, even when the proposed change builds.

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

## automatic edits

| kind | permitted form |
| --- | --- |
| `option-rename` | complete `programs.*` or `xdg.*` assignment key, with the value unchanged |
| `package-rename` | `pkgs.*` attribute reference |
| `library-rename` | `lib.*` attribute reference |

a failed log must explicitly suggest the replacement and name both final identifiers.
only existing Nix files under `modules/features/` and `packages/` are candidates.
server features, protected paths, and protected identifiers are excluded by `policy.py`.
feature activation cannot change.
strings and comments are not edit targets.

hash changes, source patches, dependency additions, input rollbacks, and uncertain migrations produce reports without automatic edits.

## execution limits

| limit | value |
| --- | --- |
| diagnosis attempts | one per workflow attempt, with no automatic retry loop |
| model duration | ten minutes |
| model turns | 24 |
| reported model tokens | 250,000, checked after each response |
| snapshot tool calls | 40 successful result attempts |
| edits | 12, at most one per source line |
| changed files | three |
| validation parallelism | two runners |
| validation duration | 360 minutes per target, including its required baseline |
| artifact retention | 14 days |

token limits can be exceeded by the final in-flight response.
source reads return bounded ranges from an in-memory snapshot.
no shell, filesystem write, web, MCP, project extension, or ambient configuration tool is available to the model.
files under `secrets/` are not read into that snapshot.

## publication

publication requires eight successful receipts with the same source SHA, baseline SHA, proposal digest, and Git tree.
the publisher reapplies the rename policy before it constructs that tree.
the GitHub-created tree must match the validated tree exactly.

branch updates are non-force pushes with the failed update commit as their only parent.
a changed PR head or base stops publication.
owner text outside the managed description section is preserved.
a bot comment records the diagnosis and result.

`update-flake / repair-validation` applies to the new repair commit.
it reports target builds, not cache uploads.
the original `update-flake / validation` result remains attached to the initial update commit.
the original workflow remains failed when its original build jobs failed.
validation does not rely on another workflow starting from the bot push.

there is no automatic merge, deployment, input rollback, cache upload, or host activation in the repair path.
