{ den, inputs, ... }:

{
  den.hosts.x86_64-linux.quasar = {
    users.gabe = { };
    # users.data = { };

    settings = {
      base = {
        dockerDNS = [ "192.168.50.1" ];
        fs.btrfs = true;
        fs.zfs = true;
      };

      network.ip = "192.168.50.208";

      portainer.dataDir = "/pool/data/portainer";

      tunnel.id = "7f867cbe-8898-4ff6-be4c-8a3ab626b456";

      gpu.nvidia.enable = true;
    };
  };

  den.aspects.quasar = {
    includes = [
      den.aspects.quasar-fs
      den.aspects.base
      den.aspects.adguard
      den.aspects.cockpit
      # den.aspects.server
      den.aspects.network
      den.aspects.network._.server
      den.aspects.grafana
      den.aspects.homepage
      den.aspects.loki
      den.aspects.navidrome
      den.aspects.plex
      den.aspects.prometheus
      den.aspects.tunnel
      den.aspects.coredns
      den.aspects.ddclient
      den.aspects.flood
      den.aspects.github-runner
      den.aspects.hercules-ci-agent
      den.aspects.pocket-id
      den.aspects.portainer
      den.aspects.startpage
      den.aspects.stirling-pdf
      den.aspects.uptime-kuma

      den.aspects.gpu
    ];

    nixos = { config, ... }: {
      imports = with inputs.nixos-hardware.nixosModules; [
        common-cpu-intel-cpu-only
        common-gpu-nvidia-nonprime
        common-pc-ssd
      ];

      hardware.facter.reportPath = ./facter.json;

      hardware.nvidia = {
        branch = "legacy_580";
        nvidiaSettings = false;
        open = false;
      };

      backup.restic = {
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

      system.stateVersion = "23.11";

      # TODO: see if this is still needed
      boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

      # TODO: should i switch it to 75d9f980 ? (etc/machine-id)
      networking.hostId = "74996f49";

      # fix home-manager not working on temp VMs
      # https://github.com/nix-community/home-manager/issues/6364#issuecomment-2965010115
      home-manager.useUserPackages = true;
      # home-manager.backupFileExtension = "bak";

      sops.secrets =
        let
          sopsFile = ../../../secrets/hosts/quasar/secrets.yaml;
        in
        {
          restic_password.sopsFile = sopsFile;
          restic_repository_config.sopsFile = sopsFile;
          restic_repository_home.sopsFile = sopsFile;
        };
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ moonlight-qt ];
      };
  };

  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
}
