{ pkgs, stable, small }:

{
  # packages with an actual source
  beekeeper-studio-ultimate = pkgs.callPackage ./beekeeper-studio-ultimate { };
  dashy = stable.callPackage ./dashy { };
  ente-desktop = pkgs.callPackage ./ente-desktop { };
  imv-patched = pkgs.callPackage ./imv { };
  iosevka-custom = stable.callPackage ./iosevka-custom { };
  moondeck-buddy = pkgs.callPackage ./moondeck-buddy { };
  seabird = stable.callPackage ./seabird { };
  syspower = pkgs.callPackage ./syspower { };
  vuetorrent = pkgs.callPackage ./vuetorrent { };

  # personal scripts
  switchup = pkgs.callPackage ./switchup { };
  nix-inspect = pkgs.callPackage ./nix-inspect { };
  minicava = pkgs.callPackage ./minicava { };
  lyrics = pkgs.python3Packages.callPackage ./lyrics { };

  # python packages
  python-music-assistant =
    pkgs.python3Packages.callPackage ./python/music-assistant { };
  soundcloudpy = pkgs.python3Packages.callPackage ./python/soundcloudpy { };

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
  home-assistant-dwains-dashboard =
    pkgs.callPackage ./home-assistant/dwains-dashboard { };
  home-assistant-grocy = pkgs.callPackage ./home-assistant/grocy { };
  home-assistant-music-assistant =
    pkgs.callPackage ./home-assistant/music-assistant { };
  home-assistant-spotcast = pkgs.callPackage ./home-assistant/spotcast { };
  home-assistant-var = pkgs.callPackage ./home-assistant/var { };
  home-assistant-lovelace-custom-brand-icons =
    pkgs.callPackage ./home-assistant/custom-brand-icons { };
  home-assistant-lovelace-bubble-card =
    pkgs.callPackage ./home-assistant/bubble-card { };
  home-assistant-lovelace-ha-firemote =
    pkgs.callPackage ./home-assistant/ha-firemote { };
  home-assistant-lovelace-horizon-card =
    pkgs.callPackage ./home-assistant/horizon-card { };
  home-assistant-lovelace-waze-travel-time =
    pkgs.callPackage ./home-assistant/waze-travel-time { };

  # font Packages
  dank-mono = pkgs.callPackage ./dank-mono { };
}
