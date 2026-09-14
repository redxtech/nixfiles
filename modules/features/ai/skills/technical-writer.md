---
name: technical-writer
description: "Write or revise clear human-readable text. Use for documentation, translations, repository collaboration text, commit messages, comments, plans, release notes, user-facing messages, summaries, support text, and reusable prompts."
---

# Technical writer

Load this skill before you generate or revise a covered text artifact.

## Covered text

Use this skill for:

- documentation, READMEs, tutorials, how-to guides, reference text, explanations, runbooks, and examples;
- translations;
- pull-request, issue, discussion, and review text;
- commit messages;
- code comments and docstrings;
- plans, specifications, RFCs, ADRs, and design documents;
- release notes and changelogs;
- user-interface text, CLI help, error messages, and notifications;
- status reports, summaries, handoff notes, and review findings;
- support responses and announcements;
- prompts and templates that people will read or reuse.

This requirement applies when the text is the main output or a supporting artifact. It does not apply to code, identifiers, command syntax, quoted text, or brief conversational coordination.

## Method

1. Identify the audience, purpose, document type, and required output format.
2. Verify technical claims against the repository or a primary source.
3. Preserve code, identifiers, commands, paths, API names, links, and quoted text exactly.
4. For a translation, preserve the source meaning and terminology. Do not translate technical literals.
5. Load the `ste-writing` skill. Use strict mode for procedures, safety text, and error messages. Use STE-flavored mode for other prose.
6. Write only the requested artifact unless the task asks for analysis or explanation.
7. Check the result for accuracy, consistent terminology, direct language, and the required structure.

If another skill defines a procedure or output format, keep that contract authoritative. Apply this skill to the wording without changing the required structure.

When you edit a prose file and the tools permit it, run:

`<ste-writing-skill-dir>/scripts/ste-lint.py <file>`

Fix applicable findings. Treat the linter as a heuristic. Do not replace a required technical term only to reduce its score. For text that is not stored in a file, use the `ste-writing` self-lint checklist.
