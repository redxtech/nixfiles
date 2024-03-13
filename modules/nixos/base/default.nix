{ inputs, outputs, pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkDefault mkOption mkEnableOption;
  inherit (config.networking) hostName;
  inherit (builtins) map;
  cfg = config.base;
  # only enable auto upgrade if current config came from a clean tree
  # this avoids accidental auto-upgrades when working locally.
  isClean = inputs.self ? rev;
in {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops

    ./cli.nix
    ./cockpit.nix
    ./nix.nix
    ./ssh.nix
    ./virtualization.nix
  ];

  options.base = with lib.types; {
    enable = mkEnableOption "Enable the base system module.";
    hostname = mkOption {
      type = str;
      default = "nixos";
      description = "The hostname of the machine.";
    };

    primaryUser = mkOption {
      type = str;
      default = "gabe";
      description = "Primary user for permissions and defaults.";
    };

    tz = mkOption {
      type = str;
      default = "America/Vancouver";
      description = "The timezone of the machine.";
    };

    autoupdate = mkOption {
      type = bool;
      default = true;
      description = "Enable automatic updates.";
    };

    tailscale = mkOption {
      type = bool;
      default = true;
      description = "Enable tailscale.";
    };
  };

  config = mkIf cfg.enable {
    networking.hostName = cfg.hostname;

    time.timeZone = mkDefault cfg.tz;

    # pass default arts to home-manager modules
    home-manager.extraSpecialArgs = { inherit inputs outputs; };

    # basic packages
    environment.systemPackages =
      let py-pkgs = ps: with ps; [ dbus-python pygobject3 requests ];
      in with pkgs; [
        curl
        file
        gcc
        git
        htop
        killall
        librsvg
        lsb-release
        man-pages
        man-pages-posix
        neovim
        ps_mem
        sqlite
        unrar
        unzip
        wget
        xclip
        w3m

        nodejs
        (python3.withPackages py-pkgs)
      ];

    # sops
    sops = let
      isEd25519 = k: k.type == "ed25519";
      getKeyPath = k: k.path;
      keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
    in { age.sshKeyPaths = map getKeyPath keys; };

    # defaults
    networking.networkmanager.enable = mkDefault true;
    hardware.enableRedistributableFirmware = mkDefault true;
    i18n.defaultLocale = mkDefault "en_CA.UTF-8";
    i18n.supportedLocales =
      mkDefault [ "en_CA.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];

    # tailscale
    services.tailscale = mkIf cfg.tailscale {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = lib.mkDefault "client";
    };

    # firewall for tailscale
    networking.firewall = {
      checkReversePath = "loose";
      allowedUDPPorts = [ 41641 ]; # Facilitate firewall punching
    };

    # auto upgrade if enabled
    system.autoUpgrade = mkIf cfg.autoupdate {
      enable = isClean;
      dates = "hourly";
      flags = [ "--refresh" ];
      flake = "github:redxtech/nixfiles#${hostName}";
    };

    # Only run if current config (self) is older than the new one.
    systemd.services.nixos-upgrade = lib.mkIf config.system.autoUpgrade.enable {
      serviceConfig.ExecCondition = lib.getExe
        (pkgs.writeShellScriptBin "check-date" ''
          lastModified() {
            nix flake metadata "$1" --refresh --json | ${
              lib.getExe pkgs.jq
            } '.lastModified'
          }
          test "$(lastModified "${config.system.autoUpgrade.flake}")"  -gt "$(lastModified "self")"
        '');
    };

    # pwless sudo
    security.sudo = {
      enable = true;

      extraRules = let
        mkRule = pkg: cmd: rules: [
          {
            command = "${pkg}/bin/${cmd}";
            options = rules;
          }
          {
            command = "/run/current-system/sw/bin/${cmd}";
            options = rules;
          }
        ];
        mkNoPwd = pkg: cmd: mkRule pkg cmd [ "NOPASSWD" ];
      in [{
        commands = (mkNoPwd pkgs.unixtools.fdisk "fdisk -l")
          ++ (mkNoPwd pkgs.ps_mem "ps_mem");
        groups = [ "wheel" ];
      }];
    };

    # increase open file limit for sudoers
    security.pam.loginLimits = mkDefault [
      {
        domain = "@wheel";
        item = "nofile";
        type = "soft";
        value = "524288";
      }
      {
        domain = "@wheel";
        item = "nofile";
        type = "hard";
        value = "1048576";
      }
    ];
  };
}
