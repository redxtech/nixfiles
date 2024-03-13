{ inputs, outputs, pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkOption;
  cfg = config.base;
in {
  options.base.cockpit = {
    enable = mkOption {
      default = true;
      description = "Enable Cockpit web interface";
    };
  };

  config = mkIf (cfg.enable && cfg.cockpit.enable) {
    services.cockpit = {
      enable = true;

      package = pkgs.cockpit.overrideAttrs (old: {
        # remove packagekit and selinux, don't work on NixOS
        postBuild = ''
          ${old.postBuild}

          rm -rf \
            dist/packagekit \
            dist/selinux
        '';
      });

      port = lib.mkDefault 9090;
      openFirewall = true;

      settings.WebService.AllowUnencrypted = true;
    };

    # extra cockpit modules
    environment.systemPackages = with pkgs; [
      cockpit-benchmark
      cockpit-docker
      cockpit-file-sharing
      cockpit-machines
      cockpit-tailscale
      libvirt-dbus
      virt-manager
    ];
  };
}

