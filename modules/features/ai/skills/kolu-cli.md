---
name: kolu-cli
description: "Drive Kolu terminals through kaval-tui and padi-tui. Use for spawning terminal agents, sending prompts, reading screens, waiting for completion, or inspecting workspace state without MCP."
---

# Kolu CLI

Use the two focused clients against Kolu's running daemons:

- `kaval-tui` owns terminal lifecycle and PTY input/output.
- `padi-tui` owns workspace, repository, branch, and agent state.

## Drive a terminal

1. Discover existing terminals with `kaval-tui list --json` or workspace state with `padi-tui status --json`.
2. Create only when needed:
   - `kaval-tui create -- <command>` for a terminal.
   - `padi-tui create --worktree <branch> --repo <path> -- <agent>` for a worktree-backed agent.
3. Send a normal prompt as three distinct operations:

   ```sh
   kaval-tui send <id> "prompt"
   kaval-tui wait <id> --until idle:300 --timeout 30000 --json
   kaval-tui send <id> --key Enter --json
   ```

   For a large brief, write it to a file and send a short instruction to read that file.
4. Wait for completion with `padi-tui wait <id> --until awaiting,waiting --json` when agent hooks are available. Otherwise use `kaval-tui wait` with an idle or match condition.
5. Read only the needed screen region with `kaval-tui snapshot <id> --viewport` or `--tail <lines>`. Use `history` only for older scrollback.
6. Continue the same terminal by sending follow-up input. Kill it only when its work is complete and no continuation is needed.

The task is complete when the terminal reaches the expected state and its relevant output has been captured.

Use `--host <ssh>` for a remote Kolu/Padi host. Preserve JSON output for lifecycle and wait operations so failures are distinguished from timeout, disappearance, interruption, or closure.