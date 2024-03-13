{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkDefault mkOption mkEnableOption;
  inherit (config.networking) hostName;
  cfg = config.base;
  # only enable auto upgrade if current config came from a clean tree
  # this avoids accidental auto-upgrades when working locally.
  isClean = inputs.self ? rev;
in {
  imports = [ ./nix.nix ];

  options.base = with lib.types; {
    enable = mkEnableOption "Enable the base system module.";
    hostname = mkOption {
      type = str;
      default = "nixos";
      description = "The hostname of the machine.";
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

    # defaults
    networking.networkmanager.enable = mkDefault true;

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
    system.autoUpgrade = kmIf cfg.autoupdate {
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
