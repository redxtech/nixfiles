{
  pkgs,
  lib,
  config,
  ...
}:

let
  inherit (builtins) map;
  inherit (lib)
    mkIf
    mkDefault
    mkOption
    mkEnableOption
    ;

  cfg = config.base;
in
{
  imports = [
    ./cli.nix
    ./gpu.nix
    ./security.nix
    ./services.nix
    ./ssh.nix
    ./virtualization.nix
    ./yubikey.nix
  ];

  options.base = with lib.types; {
    enable = mkEnableOption "Enable the base system module.";
    hostname = mkOption {
      type = str;
      default = "nixos";
      description = "The hostname of the machine.";
    };

    domain = mkOption {
      type = str;
      default = "sucha.foo";
      description = "The domain cluster";
    };

    primaryUser = mkOption {
      type = str;
      default = "gabe";
      description = "Primary user for permissions and defaults.";
    };

    extraGroups = mkOption {
      type = listOf str;
      default = [ "plugdev" ];
      description = "Extra groups to create.";
    };

    tz = mkOption {
      type = str;
      default = "America/Vancouver";
      description = "The timezone of the machine.";
    };

    fs = {
      btrfs = mkOption {
        type = bool;
        default = false;
        description = "Enable btrfs support.";
      };
      zfs = mkOption {
        type = bool;
        default = false;
        description = "Enable zfs support.";
      };
    };

    boot.enable = mkEnableOption "Enable boot config" // {
      default = true;
    };

    tailscale = mkOption {
      type = bool;
      default = true;
      description = "Enable tailscale.";
    };

    dockerDNS = mkOption {
      type = listOf str;
      default = [ ];
      description = "DNS servers to use for docker";
    };
  };

  config = mkIf cfg.enable {
    networking.hostName = cfg.hostname;

    time.timeZone = mkDefault cfg.tz;

    # basic packages
    environment.systemPackages =
      let
        py-pkgs =
          ps: with ps; [
            dbus-python
            pygobject3
            requests
          ];
      in
      with pkgs;
      [
        btrfs-progs
        lm_sensors
        man-pages
        man-pages-posix
        nodejs
        powertop
        (python3.withPackages py-pkgs)
        unrar
        unzip
      ];

    # extra groups
    users.groups = builtins.listToAttrs (
      map (name: {
        inherit name;
        value = { };
      }) cfg.extraGroups
    );

    # sops
    sops =
      let
        isEd25519 = k: k.type == "ed25519";
        getKeyPath = k: k.path;
        keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
      in
      {
        age.sshKeyPaths = map getKeyPath keys;
      };

    # defaults
    hardware.enableRedistributableFirmware = mkDefault true;
    services.dbus.implementation = "broker";
    services.zfs.autoScrub.enable = mkDefault cfg.fs.zfs;
    services.geoclue2.enable = mkDefault true;
    services.gvfs.enable = mkDefault true;
    services.irqbalance.enable = mkDefault true;
    services.zfs.autoSnapshot.enable = mkDefault cfg.fs.zfs;
    i18n.defaultLocale = mkDefault "en_CA.UTF-8";
    i18n.supportedLocales = mkDefault [
      "en_CA.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];

    # docker changes
    virtualisation.docker = {
      # fix	dns
      daemon.settings = {
        dns = mkIf (builtins.length cfg.dockerDNS > 0) cfg.dockerDNS;
        metrics-addr = "0.0.0.0:9323";
      };
    };
  };
}
