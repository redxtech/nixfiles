{ den, lib, ... }:

{
  den.aspects.base = {
    settings = {
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

      useZen = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Use the zen kernel.";
      };
    };

    includes = [
      den.aspects.boot
      den.aspects.bluetooth
      den.aspects.cli
      den.aspects.memory
      den.aspects.network
      den.aspects.nix-config
      den.aspects.root
      den.aspects.secrets
      den.aspects.security
      den.aspects.style
      den.aspects.virtualisation
      den.aspects.virtualisation._.containers

      # services
      den.aspects.cockpit
      den.aspects.portainer

      den.aspects.auto-mount
      den.aspects.backup
      den.aspects.ssh
      den.aspects.tailscale # TODO: move to network
    ];

    nixos =
      { host, pkgs, ... }:
      let
        cfg = host.settings.base;
      in
      {
        networking.domain = lib.mkDefault "sucha.foo";

        time.timeZone = lib.mkDefault cfg.tz;

        # nixos-native user management
        services.userborn.enable = true;

        # TODO: look into cachy kernel
        boot.kernelPackages = lib.mkIf cfg.useZen pkgs.linuxKernel.packages.linux_zen;

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

          storageDriver = lib.mkIf cfg.fs.btrfs "btrfs";
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
