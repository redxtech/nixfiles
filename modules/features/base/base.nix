{ den, lib, ... }:

{
  den.aspects.base = {
    settings = {
      hostname = lib.mkOption {
        type = lib.types.str;
        default = "nixos";
        description = "The hostname of the machine.";
      };

      domain = lib.mkOption {
        type = lib.types.str;
        default = "sucha.foo";
        description = "The domain cluster";
      };

      hasDisplay = lib.mkEnableOption "Whether the host has a display";

      primaryUser = lib.mkOption {
        type = lib.types.str;
        default = "gabe";
        description = "Primary user for permissions and defaults.";
      };

      tz = lib.mkOption {
        type = lib.types.str;
        default = "America/Edmonton";
        description = "The timezone of the machine.";
      };

      fs = {
        btrfs = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable btrfs support.";
        };

        zfs = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable zfs support.";
        };
      };

      dockerDNS = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "DNS servers to use for docker";
      };
    };

    includes = [
      den.aspects.boot
      den.aspects.cli
      den.aspects.network
      den.aspects.nix-config
      den.aspects.root
      den.aspects.secrets
      den.aspects.style

      den.aspects.auto-mount
      den.aspects.backup
      den.aspects.ssh
      den.aspects.tailscale
    ];

    nixos =
      { host, pkgs, ... }:
      let
        cfg = host.settings.base;
      in
      {
        networking.hostName = cfg.hostname;

        time.timeZone = lib.mkDefault cfg.tz;

        # nixos-native user management
        services.userborn.enable = true;

        # defaults
        hardware.enableRedistributableFirmware = lib.mkDefault true;
        services.dbus.implementation = "broker";
        services.zfs.autoScrub.enable = lib.mkDefault cfg.fs.zfs;
        services.geoclue2.enable = lib.mkDefault true;
        services.gvfs.enable = lib.mkDefault true;
        services.irqbalance.enable = lib.mkDefault true;
        services.zfs.autoSnapshot.enable = lib.mkDefault cfg.fs.zfs;
        i18n.defaultLocale = "en_CA.UTF-8";
        i18n.extraLocales = [
          "en_CA.UTF-8/UTF-8"
          "en_US.UTF-8/UTF-8"
        ];

        # docker changes
        virtualisation.docker = {
          # fix	dns
          daemon.settings = {
            dns = lib.mkIf (builtins.length cfg.dockerDNS > 0) cfg.dockerDNS;
            metrics-addr = "0.0.0.0:9323";
          };
        };

        # for interacting with qmk keyboards + etc
        users.groups.plugdev = { };

        environment.systemPackages =
          with pkgs;
          [
            lm_sensors
            man-pages
            man-pages-posix
            powertop
          ]
          ++ lib.optionals cfg.fs.btrfs [ btrfs-progs ];

        # fix shutdown taking a long time
        # https://gist.github.com/worldofpeace/27fcdcb111ddf58ba1227bf63501a5fe
        # TODO: do we need this?
        # systemd.settings.Manager = {
        #   DefaultTimeoutStopSec = "10s";
        #   DefaultTimeoutStartSec = "10s";
        # };
      };

    homeManager = {
      home.language.base = "en_CA.UTF-8";

      systemd.user.startServices = "sd-switch";

      # install home-manager docs
      manual = {
        html.enable = true;
        json.enable = lib.mkDefault true;
      };
    };
  };
}
