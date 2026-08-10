---
name: cyber-mux
description: Control terminal panes and pane-associated Git worktrees through cyber-mux's backend-neutral tmux/herdr interface. Use when a task needs a visible or persistent pane, an interactive or long-running process outside the current shell, input/output control of an existing pane, or a worktree opened in its own terminal space.
compatibility: Requires the cyber-mux CLI and, for pane operations, a detected tmux or herdr session.
---

# cyber-mux

Use `cyber-mux` as the pane-control seam. Do not call `tmux` or `herdr` directly.

## Choose the correct interface

Use `cyber-mux` for:

- opening a visible pane, tab, or workspace;
- running an interactive or long-lived command outside the current shell;
- sending input to, reading, waiting on, focusing, or closing a pane;
- creating or opening a Git worktree in its own terminal space;
- driving an agent CLI when its terminal must stay visible or accept human intervention.

Do not use it for:

- one-shot, non-interactive commands that `bash` can run directly;
- ordinary delegated work that builtin subagents can perform without a visible terminal;
- Kolu workspace or agent-state operations that require Kolu's own model rather than generic pane transport.

## Inspect before acting

Run:

```bash
cyber-mux doctor --format agent
cyber-mux list --format agent
```

If no multiplexer is detected, pane commands are unavailable. Do not fake `CYBER_MUX` or `CYBER_MUX_PANE`; use the current shell or a builtin subagent instead.

Prefer `--format agent` for compact output. Keep the exact pane ID returned by `open` or `list`; do not infer IDs. Run `cyber-mux <command> --help` rather than guessing flags.

## Open and drive a pane

Open the narrowest suitable placement:

```bash
cyber-mux open \
  --at pane:right \
  --cwd "$PWD" \
  --label dev-server \
  --launch 'npm run dev' \
  --format agent
```

Record the returned `pane` field as `<pane-id>`. Use `pane:right` or `pane:down` for adjacent work, `tab` for a separate view, and `workspace` for an isolated activity.

For a prompt or command that should immediately take the pane's turn, prefer `submit`:

```bash
cyber-mux submit '<pane-id>' 'Run the focused test and explain any failure' --format agent
```

Use staged text or key presses only when the interaction requires them:

```bash
cyber-mux send text '<pane-id>' 'partially staged text' --format agent
cyber-mux submit '<pane-id>' --format agent
cyber-mux send keys '<pane-id>' C-c --format agent
```

`send text` never presses Enter. `submit` always presses Enter, including when no text is supplied. `send keys` presses named keys and does not type literal text.

## Observe without busy polling

Read a bounded tail:

```bash
cyber-mux read '<pane-id>' --lines 80 --format agent
```

Wait for a stable literal output marker when driving a generic process:

```bash
cyber-mux wait '<pane-id>' --match 'ready' --timeout 120000 --lines 120 --format agent
```

Prefer `--match` over `--regex`. Treat exit status 1 as a timeout, then inspect with `read`; do not start a tight polling loop.

Under herdr, prefer the native lifecycle feed for an agent pane:

```bash
cyber-mux agent status '<pane-id>' --format agent
cyber-mux agent wait '<pane-id>' --until idle done blocked --timeout 120000 --format agent
```

`agent wait` is herdr-only. On an unsupported backend, use bounded `wait`/`read` instead.

## Worktrees

Use the worktree helpers when isolation and a visible terminal are both useful:

```bash
cyber-mux worktree add \
  --branch feature/example \
  --base HEAD \
  --at workspace \
  --label feature-example \
  --launch pi \
  --format agent
```

Inspect before cleanup:

```bash
cyber-mux worktree list --format agent
cyber-mux worktree prune --format agent
```

Bare `worktree prune` is a preview. Do not pass `--force` to `worktree remove` or `worktree prune` unless the user explicitly authorizes discarding/removing the affected worktree.

## User-interface safety

- Do not `focus` a pane unless the user asks or the task requires handing control to them.
- Close only panes created for the current task, unless the user explicitly identifies another pane to close.
- Before closing, confirm the pane ID with `exists` or `list` and read its final output when work may still be running.
- Never send input to a pane based only on its position or a guessed label.
