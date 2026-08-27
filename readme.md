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

## packages

<details>
<summary>show 60 packages</summary>

| package | version | description | upstream |
| --- | --- | --- | --- |
| [`betterbird`](packages/betterbird/package.nix) | `153.1.0esr-bb7` | Fine-tuned version of Mozilla Thunderbird | [source](https://github.com/Betterbird/thunderbird-patches) |
| [`codebase-memory-mcp`](packages/codebase-memory-mcp/package.nix) | `0.10.8` | MCP server that builds and queries a semantic graph of your codebase | [source](https://github.com/DeusData/codebase-memory-mcp) |
| [`cua-driver`](packages/cua-driver/package.nix) | `0.21.0` | Cross-platform MCP server for computer-use automation | [source](https://github.com/trycua/cua) |
| [`cyber-mux`](packages/cyber-mux/package.nix) | `0.5.0` | Cross-multiplexer pane control for AI-agent tooling | [source](https://github.com/cyberuni/cyber-mux) |
| [`docker-axi`](packages/axi/package.nix) | `0-unstable-2026-07-09` | Agent-facing Docker CLI for safe, token-efficient workflows | [source](https://github.com/thatdudealso/docker-axi) |
| [`gh-axi`](packages/gh-axi/package.nix) | `0.1.33` | GitHub CLI wrapper optimized for autonomous agents | [source](https://github.com/kunchenguid/gh-axi) |
| [`gws-axi`](packages/gws-axi/package.nix) | `0.21.0` | Agent-ergonomic CLI for Google Workspace | [source](https://github.com/JarvusInnovations/gws-axi) |
| [`himalaya-tui`](packages/himalaya-tui/package.nix) | `0.1.0-unstable-2026-08-16` | TUI to manage emails | [source](https://github.com/pimalaya/himalaya-tui) |
| [`input-custom`](packages/input-custom/package.nix) | `1.2` | Input fonts with configurable selection, spacing, and letter forms | [source](https://input.djr.com/) |
| [`kagi-mcp`](packages/kagi-mcp/package.nix) | `1.0.6` | MCP server for Kagi search and summarization | [source](https://github.com/kdcokenny/kagi-rs) |
| [`kubernetes-axi`](packages/axi/package.nix) | `0-unstable-2026-07-11` | Agent-facing Kubernetes CLI for safe, token-efficient workflows | [source](https://github.com/thatdudealso/kubernetes-axi) |
| [`mcp-remote`](packages/mcp-remote/package.nix) | `0.1.49` | Remote proxy for Model Context Protocol clients | [source](https://github.com/geelen/mcp-remote) |
| [`minicava`](packages/minicava/package.nix) | `0-unstable-2023-01-28` | A miniature cava sound visualizer | [source](https://github.com/Misterio77/minicava) |
| [`moondeck-buddy`](packages/moondeck-buddy/package.nix) | `1.9.2` | Helper to work with moonlight on a steamdeck | [source](https://github.com/FrogTheFrog/moondeck-buddy) |
| [`moshi`](packages/moshi/package.nix) | `0.3.0` | Daemon and CLI that bridges AI coding agents to the Moshi mobile app | [source](https://getmoshi.app) |
| [`nix-inspect`](packages/nix-inspect/package.nix) | `unversioned` | lists the nix store packages represented in the current PATH | — |
| [`nostalgy`](packages/nostalgy/package.nix) | `5.0.5` | Keyboard-oriented message filing and folder navigation for Thunderbird | [source](https://github.com/opto/nostalgy-xpi) |
| [`openportal`](packages/openportal/package.nix) | `0.1.32` | Mobile-first web interface for coding agents | [source](https://github.com/hosenur/portal) |
| [`orca`](packages/orca/package.nix) | `1.4.188` | ADE for working with a fleet of parallel coding agents | [source](https://github.com/stablyai/orca) |
| [`papra-cli`](packages/papra-cli/package.nix) | `0.2.5` | Command-line interface for the Papra document management platform | [source](https://github.com/papra-hq/papra) |
| [`paseo`](packages/paseo/package.nix) | `0.5.1` | Control AI coding agents from the command line | [source](https://github.com/getpaseo/paseo) |
| [`pg-axi`](packages/axi/package.nix) | `0.1.2` | Agent-facing PostgreSQL CLI for safe, token-efficient workflows | [source](https://github.com/thatdudealso/pg-axi) |
| [`pi-acp`](packages/pi-acp/package.nix) | `0.0.33` | ACP adapter for the pi coding agent | [source](https://github.com/svkozak/pi-acp) |
| [`pitty`](packages/pitty/package.nix) | `0.5.20` | OpenTUI frontend for the Pi coding agent | [source](https://github.com/mistrjirka/PiTTy) |
| [`plex-pass`](packages/plex-pass/package.nix) | `1.43.3.10896-cb3ebc72d` | Media library streaming server | [source](https://plex.tv/) |
| [`plex-pass-raw`](packages/plex-pass/package.nix) | `1.43.3.10896-cb3ebc72d` | Media library streaming server | [source](https://plex.tv/) |
| [`reboot-to-windows`](packages/reboot-to-windows/package.nix) | `1.5` | desktop launcher that reboots directly into windows | [source](https://github.com/Wartybix/Reboot-To-Windows) |
| [`repowise`](packages/repowise/package.nix) | `0.45.0` | Codebase intelligence layer for AI coding agents | [source](https://github.com/repowise-dev/repowise) |
| [`secretspec`](packages/secretspec/package.nix) | `0.19.1` | Declarative secrets, every environment, any provider | [source](https://github.com/cachix/secretspec) |
| [`strava-mcp`](packages/strava-mcp/package.nix) | `1.2.1` | MCP server for the Strava API | [source](https://github.com/r-huijts/strava-mcp) |
| [`super-productivity-mcp`](packages/super-productivity-mcp/package.nix) | `1.5.0` | MCP server for managing Super Productivity through AI assistants | [source](https://github.com/b0x42/Super-Productivity-MCP) |
| [`sysdvr`](packages/sysdvr/package.nix) | `6.3` | Nintendo Switch game streaming client | [source](https://github.com/exelix11/SysDVR) |
| [`tbkeys-lite`](packages/tbkeys-lite/package.nix) | `2.4.3` | Custom Thunderbird keybindings with managed storage support | [source](https://github.com/wshanks/tbkeys) |
| [`voxtype-full`](packages/voxtype-full/package.nix) | `0.7.5` | Push-to-talk voice-to-text for Wayland | [source](https://github.com/peteonrails/voxtype) |
| [`workspace-mcp`](packages/workspace/package.nix) | `1.25.0` | Google Workspace MCP server and CLI | [source](https://github.com/taylorwilsdon/google_workspace_mcp) |
| [`wt-herdr`](packages/wt-herdr/package.nix) | `0-unstable-2026-06-14` | herdr agent orchestration for worktrunk worktrees | [source](https://github.com/mattarau/wt-herdr) |

<details>
<summary>show 7 cockpit packages</summary>

| package | version | description | upstream |
| --- | --- | --- | --- |
| [`cockpit-benchmark`](packages/cockpit/benchmark/package.nix) | `2.1.3` | Cockpit UI for benchmarking storage | [source](https://github.com/45Drives/cockpit-benchmark) |
| [`cockpit-docker`](packages/cockpit/docker/package.nix) | `0-unstable-2024-03-02` | Cockpit UI for docker containers | [source](https://github.com/pk5ls20/cockpit-docker-upstream-mrevjd) |
| [`cockpit-file-sharing`](packages/cockpit/file-sharing/package.nix) | `4.6.1-2` | Cockpit UI for managing shares | [source](https://github.com/45Drives/cockpit-file-sharing) |
| [`cockpit-machines`](packages/cockpit/machines/package.nix) | `355` | Cockpit UI for virtual machines | [source](https://github.com/cockpit-project/cockpit-machines) |
| [`cockpit-podman`](packages/cockpit/podman/package.nix) | `129` | Cockpit UI for podman containers | [source](https://github.com/cockpit-project/cockpit-podman) |
| [`cockpit-tailscale`](packages/cockpit/tailscale/package.nix) | `0.0.6` | Cockpit UI for tailscale | [source](https://github.com/spotsnel/cockpit-tailscale) |
| [`cockpit-zfs-manager`](packages/cockpit/zfs-manager/package.nix) | `0-unstable-2024-01-09` | Cockpit UI for managing ZFS | [source](https://github.com/leroycep/cockpit-zfs-manager) |

</details>

<details>
<summary>show 17 home assistant packages</summary>

| package | version | description | upstream |
| --- | --- | --- | --- |
| [`home-assistant-components-bermuda`](packages/home-assistant/components/bermuda/package.nix) | `0.8.7` | Bermuda Bluetooth/BLE Triangulation / Trilateration for HomeAssistant | [source](https://github.com/agittins/bermuda) |
| [`home-assistant-components-browser-mod`](packages/home-assistant/components/browser-mod/package.nix) | `3.2.2` | A Home Assistant integration to turn your browser into a controllable entity and media player | [source](https://github.com/thomasloven/hass-browser_mod) |
| [`home-assistant-components-dwains-dashboard`](packages/home-assistant/components/dwains-dashboard/package.nix) | `3.10.0` | An fully auto generating Home Assistant UI dashboard for desktop, tablet and mobile by Dwains for desktop, tablet, mobile | [source](https://github.com/dwainscheeren/dwains-lovelace-dashboard) |
| [`home-assistant-components-iphonedetect`](packages/home-assistant/components/iphonedetect/package.nix) | `2.5.0` | A custom component for Home Assistant to detect iPhones connected to local LAN, even if the phone is in deep sleep | [source](https://github.com/mudape/iphonedetect) |
| [`home-assistant-components-node-red`](packages/home-assistant/components/node-red/package.nix) | `4.2.3` | Companion Component for node-red-contrib-home-assistant-websocket to help integrate Node-RED with Home Assistant Core | [source](https://github.com/zachowj/hass-node-red) |
| [`home-assistant-components-pirate-weather`](packages/home-assistant/components/pirate-weather/package.nix) | `1.9.2` | Replacement for the default Dark Sky Home Assistant integration using Pirate Weather | [source](https://github.com/Pirate-Weather/pirate-weather-ha) |
| [`home-assistant-components-spotcast`](packages/home-assistant/components/spotcast/package.nix) | `4.0.1` | Home assistant custom component to start Spotify playback on an idle chromecast device as well as control spotify connect devices | [source](https://github.com/fondberg/spotcast) |
| [`home-assistant-components-tuya-local`](packages/home-assistant/components/tuya_local/package.nix) | `2026.8.0` | Local support for Tuya devices in Home Assistant | [source](https://github.com/make-all/tuya-local) |
| [`home-assistant-components-var`](packages/home-assistant/components/var/package.nix) | `0.15.5` | A custom Home Assistant component for declaring and setting generic variable entities dynamically. | [source](https://github.com/snarky-snark/home-assistant-variables) |
| [`home-assistant-lovelace-bubble-card`](packages/home-assistant/lovelace/bubble-card/package.nix) | `3.2.5` | Bubble Card is a minimalist card collection for Home Assistant with a nice pop-up touch. | [source](https://github.com/Clooos/Bubble-Card) |
| [`home-assistant-lovelace-card-tools`](packages/home-assistant/lovelace/card-tools/package.nix) | `11` | A collection of tools for other lovelace plugins to use | [source](https://github.com/thomasloven/lovelace-card-tools) |
| [`home-assistant-lovelace-config-template-card`](packages/home-assistant/lovelace/config-template-card/package.nix) | `1.3.6` | Templatable Lovelace Configurations | [source](https://github.com/iantrich/config-template-card) |
| [`home-assistant-lovelace-custom-brand-icons`](packages/home-assistant/lovelace/custom-brand-icons/package.nix) | `2026.08.3` | Custom brand icons for Home Assistant | [source](https://github.com/elax46/custom-brand-icons) |
| [`home-assistant-lovelace-ha-firemote`](packages/home-assistant/lovelace/ha-firemote/package.nix) | `4.1.9` | Apple TV, Amazon Fire TV, Fire streaming stick, Chromecast, NVIDIA Shield, onn., Roku, Xiaomi Mi, and Android TV remote control card for Home Assistant | [source](https://github.com/PRProd/HA-Firemote) |
| [`home-assistant-lovelace-horizon-card`](packages/home-assistant/lovelace/horizon-card/package.nix) | `1.5.3` | Sun Card successor: Visualize the position of the Sun over the horizon. | [source](https://github.com/rejuvenate/lovelace-horizon-card) |
| [`home-assistant-lovelace-layout-card`](packages/home-assistant/lovelace/layout-card/package.nix) | `2.4.7` | Get more control over the placement of lovelace cards. | [source](https://github.com/thomasloven/lovelace-layout-card) |
| [`home-assistant-lovelace-waze-travel-time`](packages/home-assistant/lovelace/waze-travel-time/package.nix) | `0-unstable-2020-05-15` | Home Assistant Lovelace card for Waze Travel Time Sensor | [source](https://github.com/r-renato/ha-card-waze-travel-time) |

</details>

</details>

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
