{ inputs, pkgs, config, ... }:

{
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel-cpu-only
    inputs.hardware.nixosModules.common-gpu-nvidia-nonprime
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix
    ./filesystem.nix

    ./services
  ];

  networking.hostName = "quasar";

  base = {
    enable = true;
    hostname = "quasar";
    tz = "America/Vancouver";

    fs = {
      btrfs = true;
      zfs = true;
    };

    services = {
      portainer.enable = false; # handled by ./services/containers.nix
    };
  };

  desktop = {
    enable = true;
    wm = "gnome";
  };

  nas = {
    enable = true;
    domain = "nas.gabedunn.dev";
    paths.config = "/config/pods";
  };

  backup = {
    rsync = {
      enable = true;
      paths = [ "/config" ];
      destination = "rsync:/backups/${config.networking.hostName}";
    };
  };

  # acme
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "gabe+acme@sent.at";
      dnsResolver = "1.1.1.1:53";
      dnsProvider = "cloudflare";
      environmentFile = config.sops.secrets."cloudflare_acme".path;
    };
  };

  sops.secrets."cloudflare_acme".sopsFile = ./secrets.yaml;

  sops.secrets.cachix-agent.sopsFile = ./secrets.yaml;
  sops.secrets.cachix-agent.path = "/etc/cachix-agent.token";

  system.stateVersion = "23.11";
}
