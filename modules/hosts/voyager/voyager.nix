{ inputs, den, ... }:

{
  den.hosts.x86_64-linux.voyager = {
    users.gabe = { };

    settings = {
      base = {
        hasDisplay = true;
        fs.btrfs = true;
        dockerDNS = [ "192.168.1.1" ];
        useZen = true;
      };

      gpu.amd = true;
      workstation.isLaptop = true;

      monitors = {
        enable = true;
        monitors =
          let
            isVM = false;
          in
          if isVM then
            [
              {
                name = "Virtual-1";
                primary = true;
                height = 1386;
                width = 2536;
                rate = 74.999;
                workspaces = [
                  {
                    name = "shell";
                    number = 1;
                  }
                  {
                    name = "browser";
                    number = 2;
                  }
                  {
                    name = "chat";
                    number = 3;
                  }
                  {
                    name = "music";
                    number = 4;
                  }
                ];
              }
            ]
          else
            [
              {
                name = "eDP-2";
                primary = true;
                height = 1600;
                width = 2560;
                rate = 165.0;
                scale = 1.25;
                workspaces = [
                  {
                    name = "shell";
                    number = 1;
                  }
                  {
                    name = "www";
                    number = 2;
                  }
                  {
                    name = "chat";
                    number = 3;
                  }
                  {
                    name = "files";
                    number = 4;
                  }
                  {
                    name = "music";
                    number = 5;
                  }
                  {
                    name = "six";
                    number = 6;
                  }
                  {
                    name = "seven";
                    number = 7;
                  }
                  {
                    name = "eight";
                    number = 8;
                  }
                  {
                    name = "nine";
                    number = 9;
                  }
                  {
                    name = "ten";
                    number = 10;
                  }
                ];
              }
            ];
      };

      audio.devices = [
        {
          name = "Speakers";
          matches = "alsa_output.pci-0000_00_1f.3.*";
        }
        {
          name = "Ultras";
          type = "bluetooth";
          matches = "bluez_output.BC_87_FA_26_3B_97.*";
        }
      ];
    };
  };

  # TODO: add a specialization for no-gpu mode with nixpkgs.config.rocmSupport = false

  den.aspects.voyager = {
    includes = [
      den.aspects.voyager-fs
      den.aspects.workstation

      den.aspects.ai
      den.aspects.gpu
      den.aspects.network-mounts
      # den.aspects.prime
    ];

    nixos = { config, ... }: {
      imports = [ inputs.nixos-hardware.nixosModules.framework-16-7040-amd ];

      hardware.facter.reportPath = ./facter.json;

      networking.hostId = "bd282539";

      system.stateVersion = "24.05";

      time.timeZone = "America/Edmonton";

      backup = {
        btrfs = {
          enable = true;
          subvolumes.gabe-home = "/home/gabe";
        };

        restic = {
          enable = true;
          backups = {
            home = {
              enable = true;
              repoFile = config.sops.secrets.restic_repository_home.path;
              passFile = config.sops.secrets.restic_password.path;
            };
          };
        };
      };

      # monitoring.enable = true;

      sops.secrets = {
        restic_password.sopsFile = ../../../secrets/hosts/voyager/secrets.yaml;
        restic_repository_home.sopsFile = ../../../secrets/hosts/voyager/secrets.yaml;
      };

      # fix home-manager not working on temp VMs
      # https://github.com/nix-community/home-manager/issues/6364#issuecomment-2965010115
      # TODO: remove this when not testing in a VM
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";

      # from hardware-configuration.nix
      boot.initrd.availableKernelModules = [ "usb_storage" ];
    };

  };

  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
}
