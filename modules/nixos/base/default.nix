{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkDefault mkOption mkEnableOption optional;
  inherit (config.networking) hostName;
  inherit (builtins) map;
  cfg = config.base;

  # only enable auto upgrade if current config came from a clean tree
  # this avoids accidental auto-upgrades when working locally.
  isClean = false;
  # isClean = inputs.self ? rev;
in {
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
      default = "short.af";
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
      default = "America/Edmonton";
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
      let py-pkgs = ps: with ps; [ dbus-python pygobject3 requests ];
      in with pkgs; [
        btrfs-progs
        man-pages
        man-pages-posix
        nodejs
        (python3.withPackages py-pkgs)
        unrar
        unzip
      ];

    # extra groups
    users.groups = builtins.listToAttrs (map (name: {
      inherit name;
      value = { };
    }) cfg.extraGroups);

    # sops
    sops = let
      isEd25519 = k: k.type == "ed25519";
      getKeyPath = k: k.path;
      keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
    in { age.sshKeyPaths = map getKeyPath keys; };

    # defaults
    networking.networkmanager.enable = mkDefault true;
    hardware.enableRedistributableFirmware = mkDefault true;
    # not necessary until running really low on storage
    # services.btrfs.autoScrub.enable = mkDefault cfg.fs.btrfs;
    services.zfs.autoSnapshot.enable = mkDefault cfg.fs.zfs;
    services.zfs.autoScrub.enable = mkDefault cfg.fs.zfs;
    services.geoclue2.enable = mkDefault true;
    services.gvfs.enable = mkDefault true;
    i18n.defaultLocale = mkDefault "en_CA.UTF-8";
    i18n.supportedLocales =
      mkDefault [ "en_CA.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];

    # disable networkmanager-wait-online
    systemd.services.NetworkManager-wait-online.enable = mkDefault false;

    # enable hard-linking in nix store
    nix.optimise.automatic = mkDefault true;

    # boot config
    boot = {
      loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = mkDefault 2;
          consoleMode = "max";
        };
        timeout = mkDefault 1;
        efi.canTouchEfiVariables = true;
      };

      plymouth = {
        enable = true;
        theme = "colorful_loop";
        themePackages = with pkgs; [ adi1090x-plymouth-themes ];
      };

      kernelParams = [
        "quiet"
        "loglevel=3"
        "systemd.show_status=auto"
        "udev.log_level=3"
        "rd.udev.log_level=3"
        "vt.global_cursor_default=0"
      ];

      supportedFilesystems = (optional cfg.fs.btrfs "btrfs")
        ++ (optional cfg.fs.zfs "zfs");
      zfs.forceImportRoot = mkIf cfg.fs.zfs (mkDefault false);
      consoleLogLevel = 0;
      initrd.verbose = false;
    };

    console = {
      useXkbConfig = true;
      earlySetup = mkDefault false;
    };

    # cachix-agent
    services.cachix-agent.enable = mkDefault true;

    # docker dns
    virtualisation.docker.daemon.settings.dns =
      mkIf (builtins.length cfg.dockerDNS > 0) cfg.dockerDNS;

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
  };
}
