# Agent Guidelines

## Project Information
This is a NixOS flake with configurations for multiple computers, custom package definitions, and custom modules.

The flake is following the dendritic pattern, using [denful/den](https://github.com/denful/den) as a framework.

Every feature includes all of the necessary config, including both the home-manager and nixos modules configuration in the same aspect. The features are either included by the hosts directly, or by a parent aspect that encompasses its concern.

The two main aspects are `base` and `workstation`. The `base` aspect is for things that are shared across all hosts, and the `workstation` aspect is for things that are specific to the workstations - hosts that have a display & are expected to have the tools I use on a daily basis. New aspects should be intentional about what they do and where they are imported.

### Hosts
- `bastion`: my desktop and primary workstation (workstation)
- `voyager`: my laptop (workstation)
- `quasar`: my home server (server)
- `nixiso`: a custom iso with my config available to boot to from a usb

## Important Directories
- `modules/`: everything nixos-related goes here, one file per concern.
- `lib/`: custom functions and utilities used across the flake.
- `secrets/`: sensitive information, never touch these files.

# Tools
You have access to a few tools to help with nixos development. The `nil` language server, `nixfmt` for formatting, `nix-prefetch-scripts` to pre-compute fetcher hashes, and `statix` for ensuring best practices. Use them as necessary.

Use the internet to for reference, with `wiki.nixos.org` as a resource for the nixos ecosystem.

## Code Style
- Idiomatic Nix: use inherit for hyphenated identifiers in scope, not quoted assignment
- Idiomatic Nix: use lib.optional lib.optionals lib.optionalAttrs for basic conditionals
- Idiomatic Nix: avoid with - prefer inherit to bring names into scope. with obscures where bindings come from and breaks tooling.
- Use functions available in the nixpkgs lib instead of writing your own helpers where possible
- Commenting: comments should describe why not what, code should be self documenting as to what
- Minimal changes: fix the bug, don't refactor surroundings
- This project is using flake-file to manage inputs, so inputs are defined in `flake-file.inputs`, and are written to `flake.nix` by `nix run .#write-flake`. To use a new input, add it to `flake-file.inputs`, run `nix run .#write-flake`, and then add the code that depends on it - otherwise the evaluations will fail.

## Rules
- To validate changes, use `nix eval` to find the specific output path you want to test.
- Never modify `flake.nix` directly, it is managed by `flake-file`
- Stage files with `git add -N <file>` before teseting changes, ortherwise nix will ignore them
- Use explicit file paths when using `git` command, never use `git add .` or `git commit -a`
- NEVER modify any files in the `secrets/` directory
- Use the mcp-nixos MCP server to verify package attribute paths before adding them to any configuration
- If you need clarification on any preference or decision, ask for my input
