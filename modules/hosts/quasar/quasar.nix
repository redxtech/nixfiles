{
  den,
  inputs,
  lib,
  ...
}:

{
  den.hosts.x86_64-linux.quasar = {
    users.gabe = { };
    # users.data = { };

    settings =
      let
        secretFiles = {
          ci = ../../../secrets/hosts/quasar/ci.yaml;
          containers = ../../../secrets/hosts/quasar/containers.yaml;
          home-assistant = ../../../secrets/hosts/quasar/home-assistant.yaml;
          homepage = ../../../secrets/hosts/quasar/homepage.yaml;
          shared = ../../../secrets/hosts/quasar/secrets.yaml;
        };
        aspectSecretsFiles = {
          adguard = secretFiles.containers;
          beszel = secretFiles.containers;
          booklore = secretFiles.containers;
          calibre = secretFiles.containers;
          calibre-web = secretFiles.containers;
          ddclient = secretFiles.containers;
          esphome = secretFiles.home-assistant;
          github-runner = secretFiles.ci;
          grafana = secretFiles.shared;
          hercules-ci-agent = secretFiles.ci;
          home-assistant = secretFiles.home-assistant;
          homepage = secretFiles.homepage;
          jdownloader = secretFiles.containers;
          mosquitto = secretFiles.home-assistant;
          navidrome = secretFiles.containers;
          node-red = secretFiles.home-assistant;
          paperless = secretFiles.containers;
          papra = secretFiles.containers;
          pocket-id = secretFiles.containers;
          qdirstat = secretFiles.containers;
          qui = secretFiles.containers;
          radarr = secretFiles.containers;
          sonarr = secretFiles.containers;
          tubearchivist = secretFiles.containers;
          unpoller = secretFiles.containers;
          watchtower = secretFiles.containers;
          zigbee2mqtt = secretFiles.home-assistant;
        };
      in
      lib.mapAttrs (_: secretsFile: { inherit secretsFile; }) aspectSecretsFiles
      // {
        docktail = {
          secretsFile = secretFiles.containers;
          serviceTags = [ "tag:internal-service" ];
        };

        influxdb = {
          secretsFile = secretFiles.home-assistant;
          grafanaSecretsFile = secretFiles.shared;
        };

        base = {
          dockerDNS = [ "192.168.50.1" ];
          dockerStorageDriver = "overlay2";
          fs.btrfs = true;
          fs.zfs = true;
        };

        network.ip = "192.168.50.208";

        portainer.dataDir = "/pool/data/portainer";

        tailscale.advertiseTags = [ "tag:server" ];

        tunnel.id = "7f867cbe-8898-4ff6-be4c-8a3ab626b456";

        # gpu.nvidia.enable = true;
      };
  };

  den.aspects.quasar = {
    includes = [
      den.aspects.quasar-fs
      den.aspects.server
      den.aspects.tunnel
      # den.aspects.gpu
    ];

    nixos = { config, ... }: {
      imports = with inputs.nixos-hardware.nixosModules; [
        common-cpu-intel-cpu-only
        # common-gpu-nvidia-nonprime
        common-pc-ssd
      ];

      hardware.facter = {
        reportPath = ./facter.json;
        detected.dhcp.enable = false;
      };

      # hardware.nvidia = {
      #   branch = "legacy_580";
      #   nvidiaSettings = false;
      #   open = false;
      # };

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
        home.packages = [
          (pkgs.moonlight-qt.override { ffmpeg = pkgs.ffmpeg_8; })
        ];
      };
  };

  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
}
