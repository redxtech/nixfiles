{ inputs, pkgs, config, ... }:

{
  imports = [
    inputs.hardware.nixosModules.dell-xps-15-7590-nvidia

    ./hardware-configuration.nix
    ./filesystem.nix

    ./services.nix

    ../common/global
    ../common/users/root
    ../common/users/gabe
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

  system.stateVersion = "22.11";
}
