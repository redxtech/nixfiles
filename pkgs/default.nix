{ pkgs ? import <nixpkgs> { } }: rec {

  # Packages with an actual source
  beekeeper-studio-ultimate = pkgs.callPackage ./beekeeper-studio-ultimate { };
  dashy = pkgs.callPackage ./dashy { };
  # rgbdaemon = pkgs.callPackage ./rgbdaemon { };
  seabird = pkgs.callPackage ./seabird { };
  # shellcolord = pkgs.callPackage ./shellcolord { };
  vuetorrent = pkgs.callPackage ./vuetorrent { };

  # Personal scripts
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

  # My slightly customized plymouth theme, just makes the blue outline white
  plymouth-nixos-blur = pkgs.callPackage ./plymouth-nixos-blur { };
}
