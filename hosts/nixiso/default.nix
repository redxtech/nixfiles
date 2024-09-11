{ self, config, lib, pkgs, system, inputs, ... }:

let inherit (self.inputs) nixpkgs;
in {
  imports = [
    # ./filesystem.nix
    # self.inputs.disko.nixosModules.disko

    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
    "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
  ];

  config = {
    # disko stuff
    system.stateVersion = config.system.nixos.version;
    # disko.devices.disk.main.imageSize = "10G";
    # boot.loader.systemd-boot.enable = true;

    networking.hostName = "nixiso";

    nixpkgs = {
      hostPlatform = lib.mkDefault "x86_64-linux";
      config.allowUnfree = true;
    };

    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" "repl-flake" ];
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://devenv.cachix.org"
          "https://gabedunn.cachix.org"
          "https://hyprland.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "gabedunn.cachix.org-1:wLWTKadNjpr2Op3rBnDZMUmUEPPIoKG87oY4PmBP8qU="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };
    };

    # ensure latest kernel & filesystem pkgs are installed
    boot = {
      kernelPackages = pkgs.linuxPackages_zen;
      supportedFilesystems =
        [ "btrfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" "ext4" ];
    };

    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true; # enables support for Bluetooth

    # set the install closure path for offline installation
    # environment.etc."install-closure".source = "${closureInfo}/store-paths";

    environment.systemPackages =
      let inherit (self.inputs.tu.packages.${pkgs.system}) tu;
      in with pkgs; [
        # cli tools to have on the iso
        atool
        bat
        btop
        curl
        dua
        eza
        fd
        file
        fzf
        git
        htop
        jq
        lsb-release
        neovim
        parted
        procps
        ps_mem
        ripgrep
        rsync
        tealdeer
        tmux
        tu
        wget
        zoxide

        # gui apps
        firefox-bin
        gparted
        google-chrome

        # system
        btrfs-progs
      ];

    environment.sessionVariables = {
      FLAKE_PATH = "${self}";
      NIXPKGS_ALLOW_UNFREE = "1";
    };

    environment.shellAliases = {
      ls = "eza --group-directories-first";
      la = "ls -al";
      l = "ls -l";
      vim = "tu";

      mkd = "mkdir -pv";
      mv = "mv -v";
      rm = "rm -i";
    };
  };
}
