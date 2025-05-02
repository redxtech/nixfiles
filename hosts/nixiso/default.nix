{ self, config, lib, pkgs, ... }:

let inherit (lib) mkDefault mkForce;
in {
  imports = [ ./filesystem.nix ./packages.nix ];

  config = {
    # disko stuff
    system.stateVersion = config.system.nixos.release;
    # disko.devices.disk.main.imageSize = "10G";
    # boot.loader.systemd-boot.enable = true;

    base = {
      enable = true;
      hostname = "nixiso";

      acme.enable = false;
      boot.enable = false;
      clamav.enable = false;
      virtualisation.enable = false;

      services = {
        cockpit.enable = false;
        portainer.enable = false;
        startpage.enable = false;
      };
    };

    nixpkgs = {
      hostPlatform = mkDefault "x86_64-linux";
      config.allowUnfree = true;
    };

    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
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
      kernelPackages = pkgs.linuxPackages_latest;
      supportedFilesystems = {
        btrfs = true;
        cifs = true;
        ext4 = true;
        f2fs = true;
        ntfs = true;
        reiserfs = true;
        vfat = true;
        xfs = true;
        zfs = false;
      };
    };

    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true; # enables support for Bluetooth

    services = {
      qemuGuest.enable = true;
      openssh.settings.PermitRootLogin = mkForce "yes";

      xremap = {
        enable = true;
        withX11 = true;
        config.modmap = [{
          name = "Global";
          remap = { "CapsLock" = "SUPER_L"; };
        }];
      };

      displayManager.autoLogin.user = mkForce "gabe";
    };

    programs.thunar.enable = true;
    programs.dconf.enable = true;

    # gnome power settings do not turn off screen
    systemd = {
      services.sshd.wantedBy = mkForce [ "multi-user.target" ];
      targets = {
        sleep.enable = false;
        suspend.enable = false;
        hibernate.enable = false;
        hybrid-sleep.enable = false;
      };
    };

    # force set passwords for users
    users.extraUsers = let
      mkISOUser = pw: {
        hashedPassword = mkForce pw;
        hashedPasswordFile = mkForce null;
      };
      isoUsers = builtins.mapAttrs (_: pw: mkISOUser pw);
    in isoUsers {
      gabe =
        "$y$j9T$.xOwShfMrSOABFsHFEPz2/$Lms67feYjaQm4IKR4EWFmIoDqffK5KsmVcfZCMJaXv0";
      root =
        "$y$j9T$Nj51AtexfLEZR1DisZK7i0$adHDufm64FBLYWtxLQwC6uvHv0faz8pXCv6IFodMwV8";
    };

    # set the install closure path for offline installation
    # environment.etc."install-closure".source = "${closureInfo}/store-paths";

    system.activationScripts.touchFishHistory = ''
      touch /home/gabe/.local/share/fish/fish_history
    '';

    environment.sessionVariables = {
      FLAKE_PATH = "${self}";
      NIXPKGS_ALLOW_UNFREE = "1";
    };
  };
}
