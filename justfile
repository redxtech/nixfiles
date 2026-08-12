set shell := ["bash", "-euo", "pipefail", "-c"]

export NIXPKGS_ALLOW_UNFREE := "1"

[parallel]
[metadata("ci")]
ci: flake-metadata flake-check dev-shell packages

flake-metadata:
    nix flake metadata

flake-check:
    nix flake check --impure --print-build-logs

dev-shell:
    nix build .#devShells.x86_64-linux.default --print-build-logs --impure

packages:
    nix build \
      .#packages.x86_64-linux.bastion \
      .#packages.x86_64-linux.codebase-memory-mcp \
      .#packages.x86_64-linux.cockpit-benchmark \
      .#packages.x86_64-linux.cockpit-docker \
      .#packages.x86_64-linux.cockpit-file-sharing \
      .#packages.x86_64-linux.cockpit-machines \
      .#packages.x86_64-linux.cockpit-podman \
      .#packages.x86_64-linux.cockpit-tailscale \
      .#packages.x86_64-linux.cockpit-zfs-manager \
      .#packages.x86_64-linux.home-assistant-components-bermuda \
      .#packages.x86_64-linux.home-assistant-components-browser-mod \
      .#packages.x86_64-linux.home-assistant-components-dwains-dashboard \
      .#packages.x86_64-linux.home-assistant-components-iphonedetect \
      .#packages.x86_64-linux.home-assistant-components-node-red \
      .#packages.x86_64-linux.home-assistant-components-pirate-weather \
      .#packages.x86_64-linux.home-assistant-components-spotcast \
      .#packages.x86_64-linux.home-assistant-components-tuya-local \
      .#packages.x86_64-linux.home-assistant-components-var \
      .#packages.x86_64-linux.home-assistant-lovelace-bubble-card \
      .#packages.x86_64-linux.home-assistant-lovelace-card-tools \
      .#packages.x86_64-linux.home-assistant-lovelace-config-template-card \
      .#packages.x86_64-linux.home-assistant-lovelace-custom-brand-icons \
      .#packages.x86_64-linux.home-assistant-lovelace-ha-firemote \
      .#packages.x86_64-linux.home-assistant-lovelace-horizon-card \
      .#packages.x86_64-linux.home-assistant-lovelace-layout-card \
      .#packages.x86_64-linux.home-assistant-lovelace-waze-travel-time \
      .#packages.x86_64-linux.kagi-mcp \
      .#packages.x86_64-linux.kimaki \
      .#packages.x86_64-linux.mcp-remote \
      .#packages.x86_64-linux.minicava \
      .#packages.x86_64-linux.moondeck-buddy \
      .#packages.x86_64-linux.nix-inspect \
      .#packages.x86_64-linux.openportal \
      .#packages.x86_64-linux.orca \
      .#packages.x86_64-linux.plex-pass \
      .#packages.x86_64-linux.plex-pass-raw \
      .#packages.x86_64-linux.quasar \
      .#packages.x86_64-linux.reboot-to-windows \
      .#packages.x86_64-linux.super-productivity-mcp \
      .#packages.x86_64-linux.vaulted \
      .#packages.x86_64-linux.vm \
      .#packages.x86_64-linux.voyager \
      .#packages.x86_64-linux.workspace-mcp \
      .#packages.x86_64-linux.write-flake \
      .#packages.x86_64-linux.write-inputs \
      .#packages.x86_64-linux.write-lock \
      --impure \
      --no-link \
      --print-build-logs
