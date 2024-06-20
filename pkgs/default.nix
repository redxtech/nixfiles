{ pkgs }:

{
  # packages with an actual source
  beekeeper-studio-ultimate = pkgs.callPackage ./beekeeper-studio-ultimate { };
  dashy = pkgs.callPackage ./dashy { };
  ente-desktop = pkgs.callPackage ./ente-desktop { };
  iosevka-custom = pkgs.callPackage ./iosevka-custom { };
  moondeck-buddy = pkgs.callPackage ./moondeck-buddy { };
  obsidian-smart-connect = pkgs.callPackage ./obsidian-smart-connect { };
  seabird = pkgs.callPackage ./seabird { };
  syspower = pkgs.callPackage ./syspower { };
  vuetorrent = pkgs.callPackage ./vuetorrent { };

  # personal scripts
  switchup = pkgs.callPackage ./switchup { };
  nix-inspect = pkgs.callPackage ./nix-inspect { };
  minicava = pkgs.callPackage ./minicava { };
  lyrics = pkgs.python3Packages.callPackage ./lyrics { };

  # cockpit modules
  cockpit-benchmark = pkgs.callPackage ./cockpit/benchmark { };
  cockpit-docker = pkgs.callPackage ./cockpit/docker { };
  cockpit-file-sharing = pkgs.callPackage ./cockpit/file-sharing { };
  cockpit-machines = pkgs.callPackage ./cockpit/machines { };
  cockpit-podman = pkgs.callPackage ./cockpit/podman { };
  cockpit-tailscale = pkgs.callPackage ./cockpit/tailscale { };
  cockpit-zfs-manager = pkgs.callPackage ./cockpit/zfs-manager { };
  libvirt-dbus = pkgs.callPackage ./libvirt-dbus { }; # for cockpit-machines

  # font Packages
  dank-mono = pkgs.callPackage ./dank-mono { };
}
