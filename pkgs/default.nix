{ pkgs, stable, small }:

{
  # packages with an actual source
  beekeeper-studio-ultimate = pkgs.callPackage ./beekeeper-studio-ultimate { };
  ente-cli = pkgs.callPackage ./ente-cli { };
  ente-desktop = pkgs.callPackage ./ente-desktop { };
  imv-patched = pkgs.callPackage ./imv { };
  iosevka-custom = stable.callPackage ./iosevka-custom { };
  moondeck-buddy = pkgs.callPackage ./moondeck-buddy { };
  seabird = stable.callPackage ./seabird { };
  syspower = pkgs.callPackage ./syspower { };

  # personal scripts
  switchup = pkgs.callPackage ./switchup { };
  nix-inspect = pkgs.callPackage ./nix-inspect { };
  minicava = pkgs.callPackage ./minicava { };
  lyrics = pkgs.python3Packages.callPackage ./lyrics { };
  reboot-to-windows = pkgs.callPackage ./reboot-to-windows { };

  # python packages
  python-music-assistant =
    pkgs.python3Packages.callPackage ./python/music-assistant { };
  soundcloudpy = pkgs.python3Packages.callPackage ./python/soundcloudpy { };
  python-tekore = pkgs.python3Packages.callPackage ./python/tekore { };
  python-unifi-ap = pkgs.python3Packages.callPackage ./python/unifi-ap { };

  # cockpit modules
  cockpit-benchmark = pkgs.callPackage ./cockpit/benchmark { };
  cockpit-docker = pkgs.callPackage ./cockpit/docker { };
  cockpit-file-sharing = pkgs.callPackage ./cockpit/file-sharing { };
  cockpit-machines = pkgs.callPackage ./cockpit/machines { };
  cockpit-podman = pkgs.callPackage ./cockpit/podman { };
  cockpit-tailscale = pkgs.callPackage ./cockpit/tailscale { };
  cockpit-zfs-manager = pkgs.callPackage ./cockpit/zfs-manager { };
  libvirt-dbus = pkgs.callPackage ./libvirt-dbus { }; # for cockpit-machines

  # home assistant components
  home-assistant-bermuda =
    pkgs.callPackage ./home-assistant/components/bermuda { };
  home-assistant-browser-mod =
    pkgs.callPackage ./home-assistant/components/browser-mod { };
  home-assistant-dwains-dashboard =
    pkgs.callPackage ./home-assistant/components/dwains-dashboard { };
  home-assistant-grocy = pkgs.callPackage ./home-assistant/components/grocy { };
  home-assistant-mail-and-packages =
    pkgs.callPackage ./home-assistant/components/mail-and-packages { };
  home-assistant-node-red =
    pkgs.callPackage ./home-assistant/components/node-red { };
  home-assistant-pirate-weather =
    pkgs.callPackage ./home-assistant/components/pirate-weather { };
  home-assistant-spotcast =
    pkgs.callPackage ./home-assistant/components/spotcast { };
  home-assistant-tuya_local =
    pkgs.callPackage ./home-assistant/components/tuya_local { };
  home-assistant-var = pkgs.callPackage ./home-assistant/components/var { };

  # home assistant lovelace cards
  home-assistant-lovelace-bubble-card =
    pkgs.callPackage ./home-assistant/lovelace/bubble-card { };
  home-assistant-lovelace-card-tools =
    pkgs.callPackage ./home-assistant/lovelace/card-tools { };
  home-assistant-lovelace-config-template-card =
    pkgs.callPackage ./home-assistant/lovelace/config-template-card { };
  home-assistant-lovelace-custom-brand-icons =
    pkgs.callPackage ./home-assistant/lovelace/custom-brand-icons { };
  home-assistant-lovelace-grocy-chores-card =
    pkgs.callPackage ./home-assistant/lovelace/grocy-chores-card { };
  home-assistant-lovelace-ha-firemote =
    pkgs.callPackage ./home-assistant/lovelace/ha-firemote { };
  home-assistant-lovelace-horizon-card =
    pkgs.callPackage ./home-assistant/lovelace/horizon-card { };
  home-assistant-lovelace-layout-card =
    pkgs.callPackage ./home-assistant/lovelace/layout-card { };
  home-assistant-lovelace-waze-travel-time =
    pkgs.callPackage ./home-assistant/lovelace/waze-travel-time { };

  # font Packages
  dank-mono = pkgs.callPackage ./dank-mono { };
}
