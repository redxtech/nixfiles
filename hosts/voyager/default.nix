{ pkgs, config, ... }:

{
  imports = [ ./hardware-configuration.nix ./filesystem.nix ];

  base = {
    enable = true;
    hostname = "voyager";

    gpu = {
      enable = true;
      # nvidia.enable = true;
    };
  };

  desktop = {
    enable = true;
    isLaptop = true;
    useZen = true;
    remap = true;
    wm = "bspwm";

    gaming = {
      enable = true;
      prime = true;
      nvidia = true;
    };
  };

  # virtualisation.docker.storageDriver = "btrfs";

  sops.secrets.cachix-agent-voyager.path = "/etc/cachix-agent.token";

  system.stateVersion = "22.11";
}
