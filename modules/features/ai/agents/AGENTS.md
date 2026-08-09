# AI feature guidelines

## Preferred agent interfaces

Use the narrowest supported interface that completes the task. Prefer compact, structured CLI output over an MCP call when the CLI has equivalent capabilities. Filter large JSON responses before returning them to the model.

- **Codebase memory:** use the `codebase-memory` MCP before broad grep/find when answering structural code questions. Index an unrecognized repository with `index_repository`, inspect it with `get_architecture` or `get_graph_schema`, and verify returned symbols against source before editing.
- **GitHub:** use `gh-axi` for GitHub operations and `gh-axi api` for uncovered endpoints. Follow its contextual next-step hints and use command-specific field filters to keep output compact. Use the underlying `gh` directly only when `gh-axi` lacks the required capability, and identify that gap first.
- **Home Assistant:** load the `home-assistant-cli` skill and use `hass-cli` for state, history, and service operations.
- **Obsidian:** load the `obsidian-cli` skill and use the official `obsidian` CLI for vault operations.
- **Kolu:** load the `kolu-cli` skill and use `kaval-tui` for terminal lifecycle/IO and `padi-tui` for workspace and agent state.
- **Vaulted:** load the `vaulted-cli` skill. Agents execute secret-dependent commands through `vaulted run --`; secret values must not enter model context.

Keep using the configured MCP for Nix ecosystem research, Super Productivity, Liftosaur, and Strava. Keep using Kagi MCP until a supported Kagi CLI exists.

If a preferred CLI lacks a required capability, identify the gap before falling back to its MCP. Use `<command> --help` rather than guessing flags.
