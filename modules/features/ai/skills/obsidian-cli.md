---
name: obsidian-cli
description: "Operate Obsidian through its official CLI. Use for vault notes, search, tasks, properties, tags, Bases, daily notes, templates, sync, or plugin development."
---

# Obsidian CLI

Use the official `obsidian` CLI so operations go through Obsidian's supported application interface.

## Workflow

1. Confirm `obsidian help` works. The CLI requires the Obsidian 1.12.7-or-newer installer and starts the application if it is not running.
2. Select the intended vault explicitly when the active vault is ambiguous.
3. Inspect `obsidian help <command>` before using an unfamiliar command.
4. Use the narrowest command and output format. Prefer JSON for structured data, `paths` for file sets, and text for one note.
5. For mutations, read the target first, apply one scoped change, then read it again to verify the result.

The task is complete when the requested vault state is observed after the operation.

## Command families

Use the CLI for search/context, read/create/append, daily notes, tasks, tags, properties, Bases queries, templates, sync, workspaces, and developer commands. For plain Markdown edits where Obsidian state is irrelevant, normal file tools remain appropriate.

Use developer commands such as plugin reload, screenshots, DOM inspection, and JavaScript evaluation only for Obsidian plugin or theme development. Keep returned DOM and search results filtered to the part needed for the task.