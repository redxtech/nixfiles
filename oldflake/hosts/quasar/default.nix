{ config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./filesystem.nix

    ./services
  ];

  base = {
    gpu = {
      enable = true;
      # nvidia.enable = true;
    };
  };

  nas = {
    enable = true;
    domain = "nas.gabedunn.dev";
    paths.config = "/config/pods";
  };

  network = {
    services = {
      grafana = 3000;
      uptime = 3301;
    };
  };

  monitoring.enable = true;
  monitoring.isHost = true;

  backup = {
    restic = {
      enable = true;
      backups = {
        config = {
          enable = true;
          repoFile = config.sops.secrets.restic_repository_config.path;
          passFile = config.sops.secrets.restic_password.path;
          extraPaths = [ "/config" ];
        };
      };
    };
  };

  # open ports for services
  networking.firewall.allowedTCPPorts = [
    25565 # minecraft
    24454 # simple voice chat (minecraft)
  ];

  # disable sudo password on server
  security.sudo.wheelNeedsPassword = false;

  services.xserver.videoDrivers = [ "nvidia" ];

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  sops.secrets = {
    cachix-agent = {
      path = "/etc/cachix-agent.token";
      sopsFile = ./secrets.yaml;
    };
    restic_password.sopsFile = ./secrets.yaml;
    restic_repository_config.sopsFile = ./secrets.yaml;
    restic_repository_home.sopsFile = ./secrets.yaml;
  };

  system.stateVersion = "23.11";
}
