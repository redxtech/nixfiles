{ inputs, den, ... }:

{
  den.hosts.x86_64-linux.voyager = {
    users.gabe = { };

    settings = {
      base.hasDisplay = true;
      workstation.isLaptop = false;
      monitors = {
        enable = true;
        monitors =
          let
            isVM = true; # TODO: remove this when not testing in a VM
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

  den.aspects.voyager = {
    includes = [
      # den.aspects.voyager-fs
      den.aspects.workstation
      den.aspects.gpu
      den.aspects.network-mounts

      # until no longer on a VM
      den.aspects.vm
    ];

    nixos = {
      imports = [ inputs.nixos-hardware.nixosModules.framework-16-7040-amd ];

      # TODO: re-enable when not testing in a VM
      # hardware.facter.reportPath = ./facter.json;

      system.stateVersion = "24.05";

      gpu.amd = true;

      # fix home-manager not working on temp VMs
      # https://github.com/nix-community/home-manager/issues/6364#issuecomment-2965010115
      # TODO: remove this when not testing in a VM
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";
    };

  };

  flake-file.inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };
}
