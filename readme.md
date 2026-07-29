[![odu CI](https://github.com/redxtech/nixfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/redxtech/nixfiles/actions/workflows/ci.yml)

# my nixos flake

this repository contains the nixos and home manager configuration for my systems.

## notice: this branch is a work in progress

the `denflake` branch moves the configuration to a dendritic layout based on [den](https://github.com/denful/den).

`bastion` and `voyager` use the new layout. some services and supporting features still need migration work.

## what is included

- nixos and home manager configurations for these systems:
  - `bastion`: my desktop and primary workstation
  - `voyager`: my framework 16 laptop
  - `quasar`: my home server
  - `nixiso`: custom installation and recovery media
  <!-- TODO: complete the dendritic implementations for quasar and nixiso. -->
- feature-based configuration through den aspects
  - each feature keeps its nixos and home manager configuration together.
  - hosts include the aspects that provide their required features.
  - the `base` aspect provides shared system and user configuration.
  - the `workstation` aspect adds graphical applications, niri, gaming, audio, and desktop services.
- remote deployments through deploy-rs
- CI through odu, omnix, github actions, and cachix
- secret management through sops-nix and age
- custom packages, modules, services, scripts, and development tools
- a development shell with nix tools, deployment tools, secret tools, and CI tools

**highlights**:

- multi-host nixos and home manager configuration with den, flake-parts, and flake-file
- typed, per-host settings for hardware and feature configuration
- local rebuilds with `nrs`, an alias for `nh os switch`
- remote deployments with `nix run .#deploy [<target>]`
- encrypted deployment secrets with sops-nix and age
- tailscale networking across hosts
- a configured niri desktop with noctalia, fish, neovim, foot, firefox, and fuzzel

## structure

- `flake.nix`: the generated flake entry point. run `nix run .#write-flake` after a module changes `flake-file` declarations.
- `modules/dendritic.nix`: the den and flake-file setup. it imports the modules and packages through `import-tree`.
- `modules/features`: feature aspects for shared, workstation, network, GPU, and AI configuration.
  - `base`: configuration shared by all hosts.
  - `workstation`: configuration for hosts with a graphical desktop.
- `modules/hosts`: host definitions, host settings, hardware reports, and file-system configuration.
- `modules/users`: user aspects and user-specific files.
- `packages`: custom package definitions exposed through the flake.
- `lib`: custom nix functions used by the configuration.
- `secrets`: encrypted host and user secrets managed by sops-nix.
- `oldflake`: configuration that has not moved to the dendritic layout. the active flake does not import it.
- `justfile`: local CI recipes used to check the flake and build its packages.

## should i use this?

![learning curve](https://i.imgur.com/vtaE76k.png)

this configuration matches my systems and preferences. it is not a general nixos distribution or a reusable starter configuration.

you can still use its aspects, modules, and packages as examples when you build your own configuration.

## how to bootstrap

install nix with the `flakes` and `nix-command` experimental features enabled.

from the repository root, start the development shell:

```console
nix develop
```

the shell provides the tools used by this repository. use these commands for common tasks:

```console
# rebuild the current host.
nrs

# rebuild a named host without the shell alias.
nh os switch .#bastion

# deploy a host through deploy-rs.
nix run .#deploy bastion

# run the local CI pipeline.
nix run .#ci

# format the repository.
nix fmt

# regenerate flake.nix after a flake-file declaration changes.
nix run .#write-flake
```

## secrets

this repository uses [`sops-nix`](https://github.com/Mic92/sops-nix) and age for deployment secrets.

the SOPS rules encrypt secrets for the required user, yubikey, host, and github actions recipients.

## tooling and applications i use

the main tools in my current workstation configuration are:

- niri
- noctalia
- neovim through my [`tu`](https://github.com/redxtech/tu) configuration
- fish
- foot
- firefox nightly
- tailscale
- docker and libvirt
- fuzzel
- `bat`, `fd`, and `ripgrep`

## unixpornish stuff

<!-- TODO: replace this image with a current busy-desktop screenshot. -->
![fakebusy](https://i.imgur.com/cJzEZJE.png)

<!-- TODO: replace this image with a current clean-desktop screenshot. -->
![clean](https://i.imgur.com/j2cjXrs.jpeg)

these screenshots show the former hyprland desktop from july 2024. they will be replace with updated screenshots soon.
