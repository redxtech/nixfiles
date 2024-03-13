{ inputs, pkgs, config, ... }:

{
  imports = [
    inputs.hardware.nixosModules.dell-xps-15-7590-nvidia

    ./hardware-configuration.nix
    ./filesystem.nix

    ../common
  ];

  base = {
    enable = true;
    hostname = "voyager";
    tz = "America/Vancouver";
  };

  desktop = {
    enable = true;
    isLaptop = true;
    useZen = true;
    wm = "bspwm";

    gaming = {
      enable = true;
      prime = true;
      nvidia = true;
    };
  };

  # virtualisation.docker.storageDriver = "btrfs";

  sops.secrets.cachix-agent.sopsFile = ./secrets.yaml;
  sops.secrets.cachix-agent.path = "/etc/cachix-agent.token";

  system.stateVersion = "22.11";
}
