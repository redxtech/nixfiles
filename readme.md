[![odu CI](https://github.com/redxtech/nixfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/redxtech/nixfiles/actions/workflows/ci.yml)

# my nixOS flake

this repository contains the nixOS and home-manager configuration for my systems.

## what is included

- nixOS and home-manager configurations for three hosts:
  - `bastion`: my desktop and primary workstation
  - `voyager`: my laptop
  - `quasar`: my home server
- feature-based configuration through [den](https://github.com/denful/den) aspects
  - `base` provides shared system and user configuration.
  - `workstation` adds the graphical desktop, applications, audio, gaming, and related services.
  - `server` adds the homelab services used by `quasar`.
- remote deployments through deploy-rs
- secret management through sops-nix and age
- CI through odu, omnix, github actions, and cachix
- custom packages, modules, services, scripts, and nix library functions

the workstation configuration uses niri, noctalia, fish, neovim, foot, firefox nightly, and tailscale.

## structure

- `modules/features`: shared, workstation, server, network, GPU, and AI aspects
- `modules/hosts`: host definitions, hardware reports, and file-system configuration
- `modules/users`: user aspects and user-specific configuration
- `packages`: custom flake packages
- `lib`: nix functions used by the configuration
- `secrets`: sops-nix encrypted files

`flake-file` generates `flake.nix` from declarations next to the modules that use them. `import-tree` loads the modules and packages.

## should i use this?

![learning curve](https://i.imgur.com/vtaE76k.png)

probably not as-is. this configuration matches my hardware, network, services, and preferences.

you can still use its aspects, modules, and packages as examples for your own configuration.

## common commands

the flake's devShell provides the repository tools and the `nrs` rebuild alias.

```fish
# rebuild the current host
nrs

# rebuild a named host
nh os switch .#bastion

# deploy a host through deploy-rs
nix run .#deploy quasar

# run the local CI pipeline
nix run .#ci

# format the repository
nix fmt

# regenerate flake.nix after a flake-file declaration changes
nix run .#write-flake

# regenerate noctalia's config after making changes via the ui
nix run .#write-noctalia
```

## secrets

this repository uses [`sops-nix`](https://github.com/Mic92/sops-nix) and age for deployment secrets.

the SOPS rules encrypt secrets for the required user, yubikey, host, and github actions recipients.

## unixpornish stuff

![fakebusy](https://i.postimg.cc/Ls4WB1V6/fakebusy.png)

![clean](https://i.postimg.cc/W49H919Z/clean.png)

these screenshots show the current niri desktop as of august 2026.
