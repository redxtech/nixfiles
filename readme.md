[![nix deploy](https://github.com/redxtech/nixfiles/actions/workflows/cachix-deploy.yaml/badge.svg)](https://github.com/redxtech/nixfiles/actions/workflows/cachix-deploy.yaml)

# my nixOS flake

this is where my configuration for everything is related.

## what is included

- system configuration definitions
  - my desktop (bastion)
  - my laptop (voyager)
  - my nas (quasar)
- home manger configurations
  - all of the above systems
  - my steamdeck (deck)
- automatic deployments via github actions and cachix-deploy
- secrets management via sops-nix
- custom package definitions
- custom nixos/home-manager modules and service definitions
  - modules and configurations for many nas-related services
  - pick & choose base system & desktop modules for consistency across systems

**highlights**:

- multi-system nixOS & home-manager configuration with **flake-parts** for easy composition
- rebuild locally with `nrs` (alias for `nh os switch`, improved `sudo nixos-rebuild`),
  and remotely with `nix run .#deploy [<target>|all]`
- deployment **secrets** using **sops-nix**
- **mesh networked** hosts with **tailscale**
- extensively configured window manager (**bspwm**), cli (**fish**), and editor (**neovim**)

## structure

> this section is not updated in-sync with the actual repository, but should give a good idea of what to expect

- `flake.nix`: entrypoint for hosts and home configurations. also exposes a
  devshell for boostrapping (`nix develop`).
- `hosts`: nixOS Configurations, accessible via `nixos-rebuild --flake`.
  - `common`: shared configurations consumed by each host.
  - `bastion`: desktop - 32GB RAM, R9 5900X, RX 7900XT | BSPWM
  - `voyager`: dell xps 15 - 16GB RAM, i7 9750H, GTX 1650 | BSPWM
  - `quasar`: home server - 32GB RAM, i7 6700K, GTX 970 | headless
- `home`: home-manager configuration, acessible via `home-manager --flake`
  each host has a file, and there's a `common` folder for shared configurations.
- `modules`: module definitions consumed by the hosts.
  - `nixos`: nixOS modules, such as custom services, hardware configurations, etc.
  - `home-manager`: home-manager modules, such as custom desktop, window manager, cli, and editor configurations.
  - `flake`: flake-parts modules used for composition, such as shells, overlays, nix config, deployments, etc.
- `pkgs`: my custom packages. also accessible via `nix build`. you can compose
  these into your own configuration by using my flake's overlay (soon), or consume them through NUR (soon).

## should I use this ?

![learning curve](https://i.imgur.com/vtaE76k.png)

it's definitely not for everyone, but it happens to be exactly what i've been looking for in a distro.
if you're not turned off by the initial learning curve, the cryptic error messages,
and the occasional stress-induced-baldness, you might be able to see how powerful nixOS can be.

## how to bootstrap

all you need is nix 2.4+, git, and to have already enabled `flakes` and
`nix-command`, you can also use the command:

```
nix develop
```

`nixos-rebuild --flake .` To build system configurations

`home-manager --flake .` To build user configurations

`nix build` (or shell or run) To build and use packages

`sops` To manage secrets

## secrets

for deployment secrets (such as user passwords and server service secrets), I'm
using the awesome [`sops-nix`](https://github.com/Mic92/sops-nix). All secrets
are encrypted with my personal PGP key (stored on a YubiKey), as well as the
relevant systems's SSH host keys.

## tooling and applications I use

most relevant user apps daily drivers:

- bspwm + xidlehook + betterlockscreen
- polybar
- neovim
- fish
- kitty
- firefox
- tailscale
- podman
- rofi
- bat + fd + rg
- kdeconnect

let me know if you have any questions about them :)

## unixpornish stuff

![fakebusy](https://i.imgur.com/tHoWWnX.png)
![clean](https://i.imgur.com/PrKM4QS.jpg)

that's how my bspwm desktop setup look like (as of 2023 December).
