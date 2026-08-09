---
name: vaulted-cli
description: "Use Vaulted safely from the CLI. Use when a command needs injected secrets or when managing Vaulted projects, environments, names, imports, or rotation."
---

# Vaulted CLI

Treat Vaulted as a secret-execution boundary: the agent may select secret names and run a process, but secret values stay outside model context.

## Agent-safe workflow

1. Confirm the current project and environment from `vaulted.toml` and metadata-only commands.
2. If the vault is locked, ask the user to run `vaulted unlock`; do not request the master password.
3. Use `vaulted list` only for names, scopes, and value types.
4. Execute secret-dependent work with direct argument passing:

   ```sh
   vaulted run -- command arg1 arg2
   ```

   Add environment, folder, or approved global-selection flags before `--` when required. Use a shell wrapper only when the target operation requires shell expansion.
5. Inspect the exit status and redacted output. Report the command outcome without reconstructing secret values.

The task is complete when the target process succeeds or returns a redacted, actionable failure.

## Guardrails

- Never run `vaulted get` or `vaulted list --reveal` as an agent.
- Never export the vault to a file for agent use.
- Use `set`, `rm`, `import`, `export`, or key rotation only when the user explicitly asks to change secret storage.
- Prefer the Vaulted MCP when an agent needs secret metadata plus hardened, redacted execution and the CLI path cannot preserve that boundary.