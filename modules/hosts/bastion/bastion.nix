{ inputs, den, ... }:

{
  den.hosts.x86_64-linux.bastion = {
    users.gabe = { };

    settings = {
      base.hasDisplay = true;
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
                name = "DP-1";
                primary = true;
                height = 1440;
                width = 2560;
                rate = 144;
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
                    name = "five";
                    number = 5;
                  }
                  {
                    name = "six";
                    number = 6;
                  }
                ];
              }
              {
                name = "DP-2";
                height = 1440;
                width = 2560;
                rate = 144;
                x = 2560;
                workspaces = [
                  {
                    name = "music";
                    number = 7;
                  }
                  {
                    name = "r-www";
                    number = 8;
                  }
                  {
                    name = "video";
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
          name = "Schiit Stack";
          matches = "alsa_output.usb-Schiit_Audio_Schiit_Unison_Modi_Multi_2-00.*";
        }
        # {
        #   name = "Speakers";
        #   matches = "alsa_output.pci-0000_2e_00*";
        # }
        {
          name = "Ultras";
          type = "bluetooth";
          matches = "bluez_output.BC_87_FA_26_3B_97.*";
        }
        {
          name = "Arctis 7 Game";
          matches = "alsa_output.usb-SteelSeries_SteelSeries_Arctis_7-00.stereo-game*";
        }
        {
          name = "Arctis 7 Chat";
          matches = "alsa_output.usb-SteelSeries_SteelSeries_Arctis_7-00.mono-chat*";
        }
        {
          name = "Sunshine Client";
          matches = "*sink-sunshine-stereo*";
        }
      ];
    };
  };

  den.aspects.bastion = {
    includes = [
      # den.aspects.bastion-fs
      den.aspects.workstation
      den.aspects.gpu
      den.aspects.network-mounts

      # until no longer on a VM
      den.aspects.vm
    ];

    nixos = {
      # imports = [ inputs.nixos-hardware.nixosModules.framework-16-7040-amd ];

      # TODO: re-enable when not testing in a VM
      # hardware.facter.reportPath = ./facter.json;

      system.stateVersion = "23.11";

      gpu.amd = true;

      # fix home-manager not working on temp VMs
      # https://github.com/nix-community/home-manager/issues/6364#issuecomment-2965010115
      # TODO: remove this when not testing in a VM
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          audacity # audio editor
          # beekeeper-studio-ultimate # database manager
          # citron # switch emulator # TODO: switch to eden
          # deluge # torrent client
          # dolphin-emu # gamecube/wii emulator
          ente-desktop # photos app
          # nautilus # file manager
          # neovide # neovim gui
          kdePackages.okular # ebook, pdf, comic, etc. reader
          reboot-to-windows # reboot to windows
        ];
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
