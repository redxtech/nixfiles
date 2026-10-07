---
name: nixfiles-modules
description: Define or modify feature aspects in this nixfiles den-based NixOS flake. Use automatically for feature configuration, aspect settings, includes, provides, and feature activation under modules/. Cover imported NixOS or Home Manager modules and helpers only when the feature needs them. Not a general host, packaging, library, or flake architecture guide.
---

# Nixfiles feature aspects

Use this skill for one feature concern and its necessary activation edges.

Paths below start at the repository root, `../../..` from this skill directory. Source anchors identify contracts, not templates to copy unchanged.

## Boundaries

Applicable `AGENTS.md` files and current user instructions govern the work.

- Never read or modify files under `secrets/`.
- Never edit generated `flake.nix` directly.
- Ask before adding a third-party dependency.
- Verify package attribute paths with mcp-nixos before adding packages to configuration.
- Preserve unrelated working-tree changes and Git index entries.
- Use explicit Git paths, never `git add .` or `git commit -a`.
- Do not deploy or switch configurations without authorization.

Keep existing aspect identifiers and directory layouts unless the task requires a change. Do not redesign hosts, packages, libraries, or flake infrastructure during routine feature work.

## 1. Inspect the feature

1. Read the repository and applicable nested `AGENTS.md` files.
2. Inspect the Git status and index.
3. Read the current feature source.
4. Trace its inclusion lists to the affected host records.
5. Read the imported modules and helper contracts that the feature needs.
6. Identify the intended behavior and affected hosts.
7. Ask foreseeable preference questions before editing.

Use working-tree content, not HEAD as a substitute.

| Layer | Purpose |
|---|---|
| Flake-parts module | Defines aspects, exports ordinary modules, or contributes `flake-file` and `perSystem` |
| Den aspect | Groups a selectable concern through `includes`, `nixos`, `homeManager`, `settings`, or `provides` |
| NixOS or Home Manager (HM) module | Defines scope-local `imports`, `options`, `config`, and module arguments |

`modules/dendritic.nix` declares import-tree discovery over `modules` and `packages`. Discovery makes definitions available. It does not activate every aspect.

## 2. Start with a simple aspect

Use focused files under the existing `modules/features/` concern directory. Use kebab-case names for new aspects.

Keep the feature's necessary NixOS and HM configuration in one aspect. Omit an unused scope. Full aspect attrsets and dotted declarations are equally valid. Do not normalize declarations solely for style.

Paired configuration from `modules/features/base/auto-mount.nix`:

```nix
{
  den.aspects.auto-mount = {
    nixos.services.udisks2.enable = true;

    homeManager =
      { pkgs, lib, ... }:
      {
        services.udiskie = {
          enable = true;
          settings.program_options.file_manager = lib.getExe' pkgs.xdg-utils "xdg-open";
        };
      };
  };
}
```

Dotted declaration from `modules/features/base/moshi.nix`:

```nix
{ self, ... }:
{
  den.aspects.moshi.homeManager = {
    imports = [ self.homeManagerModules.moshi ];
    services.moshi-hook.enable = true;
  };
}
```

File names need not match aspect identifiers. `modules/features/base/network.nix` defines `networking`, while `modules/features/network/network.nix` defines `network`.

Related files can extend one aspect. `modules/features/workstation/scripts/{options,scripts}.nix` both contribute to `den.aspects.scripts.homeManager`.

Keep aggregate aspects as explicit `includes` lists. Do not replace intentional selection with filesystem-derived activation. Keep flake-parts contributions outside the aspect attrset.

## 3. Choose the interface per option

Use upstream options first. Add a custom option only for a concrete configuration need.

| Need | Declaration | Consumer |
|---|---|---|
| Existing upstream interface | Existing NixOS or HM option | Its owning module system |
| Custom option that can remain NixOS-local | `options` inside the `nixos` contribution | NixOS `config` |
| Custom option that can remain HM-local | `options` inside the `homeManager` contribution | HM `config` |
| One custom input that configures both NixOS and HM | Declare once in aspect `settings` | Both contributions read `host.settings.<aspect>` |

Use aspect-level `settings` only for custom options that apply to both NixOS and HM configurations. Decide per option, not per aspect. A host-specific value, multiple host consumers, or an aspect containing both scopes does not justify `settings`.

This rule concerns aspect `settings`, not upstream options named `settings`.

For a truly shared custom option, declare it once in `settings`. Have both contributions consume the shared value. Do not split or duplicate that option to avoid `settings`.

Keep ordinary `options` and their implementation `config` inside the owning NixOS or HM contribution. Do not add an enable option merely because an aspect is selectable. Inclusion already selects the aspect.

### Local options and OS state

`modules/features/workstation/scripts/options.nix` declares HM-local `options.scripts`. Its companion `modules/features/workstation/scripts/scripts.nix` reads HM `config.scripts`.

`modules/features/workstation/travel.nix` declares NixOS-local `options.travel.enable`. Its HM contribution reads `osConfig.travel.enable` to follow the selected OS specialization.

HM observation of OS-owned state does not require a shared custom input. Use `osConfig` for that dependency. Do not export every OS option to aspect `settings` because HM can read it.

### Shared settings

`modules/features/workstation/apps/file-browser.nix` has a genuine shared option: `enableThunar` controls NixOS xfconf and HM Thunar configuration.

This reduced example shows that interface, not the complete application setup:

```nix
{ lib, ... }:
{
  den.aspects.file-browser = {
    settings.enableThunar = lib.mkEnableOption "Thunar" // {
      default = true;
    };

    nixos = { host, ... }: {
      programs.xfconf.enable = host.settings.file-browser.enableThunar;
    };

    homeManager = { host, pkgs, ... }: {
      home.packages = lib.optionals host.settings.file-browser.enableThunar [ pkgs.thunar ];
    };
  };
}
```

For each shared option:

1. Declare it with `lib.mkOption` or `lib.mkEnableOption`.
2. Specify its type and description.
3. Supply a meaningful default, or deliberately require a host value.
4. Read the shared value in both contributions.
5. Put host overrides under `den.hosts.<system>.<host>.settings.<aspect>`.

`modules/schema.nix` derives typed host settings from aspect declarations. This mechanism does not enforce the shared-only rule.

### Legacy interfaces are not precedents

Current source contains one-system aspect settings. These declarations do not justify new one-system settings:

| Source | Existing interface |
|---|---|
| `modules/features/workstation/audio.nix` | `devices` and `easyEffects` serve HM only, despite the aspect's NixOS contribution |
| `modules/features/gpu.nix` | GPU settings serve NixOS, including the container integration in `modules/features/base/virtualisation.nix` |
| `modules/features/server/server.nix` | Roots and IDs serve NixOS server services, not a shared NixOS/HM interface |
| `modules/features/server/services/paperless.nix` | `settings.secretsFile` supplies NixOS SOPS metadata |

Preserve untouched legacy interfaces. Reuse an established contract when the feature needs it. Do not add new one-system options to legacy aspect `settings`. Do not migrate existing interfaces without a task requirement.

## 4. Keep scopes and module semantics correct

Request only used arguments. Keep `...` in module-function argument sets.

| Scope or value | Meaning |
|---|---|
| Outer flake-parts function | Flake-level arguments such as `inputs`, `self`, `den`, and `lib` |
| Inner `nixos` function | NixOS arguments such as `config`, `pkgs`, `lib`, and contextual `host` |
| Inner `homeManager` function | HM arguments such as `config`, `pkgs`, `lib`, `osConfig`, and contextual `host` |
| `config` | Current module configuration |
| HM `osConfig` | Associated NixOS configuration |
| `host.settings` | Typed aspect settings, including existing legacy interfaces |
| `inputs'`, `self'` | System-specific outputs supplied by configured den providers |

Capture outer values lexically when needed. One inner function cannot access another inner function's bindings.

`modules/defaults.nix` selects the den providers and host-settings integration. `modules/host-settings.nix` passes `settings = host.settings` to NixOS and `host` to HM. `modules/features/ai/ai.nix` shows `inputs'` and `self'` package access.

Read the integration before relying on contextual arguments.

- Use `lib.mkIf` for conditional module definitions.
- Use `lib.optional`, `lib.optionals`, or `lib.optionalAttrs` for basic conditional values.
- Use `lib.mkMerge` when separate module fragments need a merge.
- Explain new forced overrides.
- Add assertions for invariants that types cannot express.
- Prefer existing nixpkgs library functions to new helpers.
- Use `inherit` for identifiers in scope, including hyphenated identifiers.
- Avoid `with`, including in examples adapted from legacy source.

## 5. Use advanced forms only for concrete needs

| Need | Form and source anchor |
|---|---|
| Separately selected variant | `provides.<variant>`, declared in `modules/features/base/bluetooth.nix` and selected as `den.aspects.bluetooth._.for-workstation` in `modules/features/workstation/workstation.nix` |
| Reusable ordinary module interface | Scope-level `imports`, as in Moshi above, with export in `packages/moshi/module.nix` |
| Context needed at the aspect layer | Aspect function, as in `modules/host-settings.nix`, rather than an inner module function |
| Repeated configuration within one feature | Local constructor, as in `modules/features/server/services/qbittorrent.nix` |

A provider declaration does not select it. Check its consumer and required base aspect. Do not assume provider selection supplies every prerequisite.

Use aspect `includes` for den composition. Use scope-level `imports` for ordinary NixOS or HM modules. Do not put unwrapped ordinary modules in automatically discovered flake-module locations.

AgentsView and Hermes also export HM modules through their `modules/features/ai/{agentsview,hermes}/module.nix` flake-parts wrappers. Do not create such a wrapper for every small feature.

Inner module functions suffice for ordinary configuration. Before introducing unfamiliar den machinery, inspect the pinned implementation. Ask about unresolved structural choices instead of inventing APIs.

### Containers, secrets, and assets

A containerized service remains a NixOS feature aspect. Keep its application and necessary companion containers together.

`modules/features/server/services/paperless.nix` shows an OCI network, Redis companion, persistent paths, and SOPS metadata. `modules/features/base/virtualisation.nix` defines the managed-network option and Docker units.

Check the selected backend and provider before adapting this pattern. Do not copy image tags, privileges, bind addresses, or firewall exposure as defaults.

| Source | Helper contract |
|---|---|
| `lib/containers/default.nix` | `mkPort host guest`, `mkPorts port` |
| `lib/server/default.nix` | `defaultEnvironment { uid, gid, timeZone }`, `volumes server`, `mkSecretsFileOption service` |
| `lib/containers/labels.nix` | `labels.traefik fqdn` returns `mkAllLabels name port service` and other label helpers |

Read helper signatures before use. `mkAllLabels` adds Traefik, Docktail, and Homepage labels. Use it only when the feature needs all three integrations.

For secrets, use upstream SOPS options when sufficient. Declare only metadata in feature code. Pass the generated SOPS path to the consumer. Never put secret values in Nix expressions.

`mkSecretsFileOption` constructs an ordinary option declaration. It does not require aspect `settings`. A new one-system secret-file option belongs in that system's `options`, unlike Paperless's legacy placement.

Keep related assets beside the feature. Verify relative `builtins.readFile` paths and JSON or TOML conversions. Export helpers only for a demonstrated shared contract.

## 6. Make activation explicit

1. Identify the host or parent aspect that must include the feature.
2. Confirm intended hosts when the scope is ambiguous.
3. Add the approved `includes` edge.
4. Trace the edge to every affected host output.
5. Check provider selections and companion aspects.

Use `base` for concerns intended across its consumers. Use `workstation` for display-equipped daily-use hosts. Use a direct host edge for host-specific activation.

Inspect the actual graph before choosing an edge. `modules/hosts/{bastion,voyager}/` select workstation. `modules/hosts/quasar/quasar.nix` selects server.

For web services, read `modules/features/network/{network,traefik}.nix` before registration. `network.services` feeds `network.finalServices` and Traefik. `network.tailscaleServices` is separate.

Catalog registration, firewall exposure, and control-plane service creation are different actions. Confirm intended network exposure with the user. Do not register every service for HTTP ingress.

For an approved new flake input:

1. Add `flake-file.inputs` beside the feature that uses it.
2. Make new source files visible under the Git rules below.
3. Run `nix run .#write-flake`.
4. Inspect the generated diff for unintended changes.
5. Add the code that depends on the input.

If generation conflicts with unrelated changes, report the conflict instead of overwriting those changes.

## 7. Validate feature values and full composition

### New-file visibility

Git-backed flakes exclude untracked files, including referenced assets. Repository `AGENTS.md` requires `git add -N <file>` before testing new files.

Apply intent-to-add only to exact new task files. Do not restage tracked files merely for evaluation. If current instructions forbid index changes, ask before intent-to-add. Without authorization, report the visibility blocker. Do not bypass Git filtering with an unrestricted whole-worktree path flake.

### Checks

1. Inspect the diff for intended scope.
2. Check formatting on changed Nix files.
3. Confirm Nix visibility for every new module and referenced asset.
4. Discover relevant output names with `nix eval`.
5. Evaluate feature-specific values on every affected host.
6. Evaluate each affected host's `system.build.toplevel.drvPath`.
7. If the change affects HM, evaluate each affected user's `home.activationPackage.drvPath`.
8. If activation changes, repeat relevant feature-value and composition checks on a representative non-target host, when one exists.
9. Compare results with expected values.
10. Run focused checks for changed scripts and assets.
11. Run `git diff --check` with explicit task paths.
12. Inspect the final diff for requirements, failure behavior, cleanup, and test coverage.
13. Verify that unrelated Git index entries remain intact.

Use two-space Nix indentation and spaces in multiline strings. `.editorconfig` and `modules/fmt.nix` define the formatting convention.

This formatter check does not write files:

```fish
nixfmt --check --indent=2 modules/features/base/auto-mount.nix
```

These evaluations illustrate auto-mount on voyager. Substitute the actual feature, hosts, and users. Both enable checks should return `true`.

```fish
nix eval '.#nixosConfigurations' --apply builtins.attrNames --json --no-write-lock-file --option allow-import-from-derivation false
nix eval '.#nixosConfigurations.voyager.config.services.udisks2.enable' --json --no-write-lock-file --option allow-import-from-derivation false
nix eval '.#nixosConfigurations.voyager.config.home-manager.users.gabe.services.udiskie.enable' --json --no-write-lock-file --option allow-import-from-derivation false
nix eval '.#nixosConfigurations.voyager.config.system.build.toplevel.drvPath' --raw --no-write-lock-file --option allow-import-from-derivation false
nix eval '.#nixosConfigurations.voyager.config.home-manager.users.gabe.home.activationPackage.drvPath' --raw --no-write-lock-file --option allow-import-from-derivation false
```

The flags prevent lock-file writes and import-from-derivation builds. If evaluation requires either, report the blocker before changing validation mode.

A leaf evaluation does not prove full composition. A derivation path does not prove a successful build or runtime behavior. Use the smallest additional test that proves the changed behavior.

## Completion record

Report changed paths, activation edges, affected hosts, and justified exceptions. Include each validation command, expected value, result, and skipped check with its reason. Report unavailable tools and unresolved errors. Do not claim a blocked check passed.

Keep changes minimal. Write comments about non-obvious reasons, with lowercase prose except acronyms. Do not impose this guidance on untouched features.
