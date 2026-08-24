# AI feature guidelines

## Preferred agent interfaces

Use the narrowest supported interface that completes the task. Prefer compact, structured CLI output over an MCP call when the CLI has equivalent capabilities. Filter large JSON responses before returning them to the model.

- **Codebase memory:** use the `codebase-memory` MCP before broad grep/find when answering structural code questions. Index an unrecognized repository with `index_repository`, inspect it with `get_architecture` or `get_graph_schema`, and verify returned symbols against source before editing.
- **GitHub:** use `gh-axi` for GitHub operations and `gh-axi api` for uncovered endpoints. Follow its contextual next-step hints and use command-specific field filters to keep output compact. Use the underlying `gh` directly only when `gh-axi` lacks the required capability, and identify that gap first.
- **Home Assistant:** load the `home-assistant-cli` skill and use `hass-cli` for state, history, and service operations.
- **Obsidian:** load the `obsidian-cli` skill and use the official `obsidian` CLI for vault operations.
- **Terminal multiplexers:** load the `cyber-mux` skill and use `cyber-mux` instead of calling `tmux` or `herdr` directly. Use it for visible or persistent panes, interactive or long-running processes outside the current shell, existing-pane control, and pane-associated Git worktrees. Use ordinary shell tools for one-shot non-interactive commands and builtin subagents for delegation that does not need a visible terminal.
- **Kolu:** load the `kolu-cli` skill and use `kaval-tui` or `padi-tui` only when the task specifically needs Kolu terminal, workspace, repository, branch, or agent-state semantics.

Keep using the configured MCP for Nix ecosystem research, Super Productivity, Liftosaur, and Strava. Keep using Kagi MCP until a supported Kagi CLI exists.

If a preferred CLI lacks a required capability, identify the gap before falling back to its MCP. Use `<command> --help` rather than guessing flags.
