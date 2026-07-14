{ lib, ... }:

{
  den.aspects.cockpit = {
    nixos =
      {
        self',
        host,
        config,
        pkgs,
        ...
      }:
      let
        cfg = host.settings.base;

        # TODO: fix when network aspect is set up
        inherit (cfg) domain hostname;
        cfgNet = {
          address = "${hostname}.${domain}";
        };
      in
      {
        services.cockpit = {
          enable = true;

          package = pkgs.cockpit.overrideAttrs (old: {
            # remove packagekit and selinux, don't work on NixOS
            postBuild = ''
              rm -rf \
                dist/packagekit \
                dist/selinux
            '';
          });

          port = 9090;
          openFirewall = true;

          allowed-origins = [
            "http://localhost:9090"
            "ws://localhost:9090"
            "http://${cfg.hostname}:9090"
            "ws://${cfg.hostname}:9090"

            "https://${cfgNet.address}"
            "wss://${cfgNet.address}"
            "https://cockpit.${cfgNet.address}"
            "wss://cockpit.${cfgNet.address}"
          ];

          settings.WebService = {
            AllowUnencrypted = true;
            ProtocolHeader = "X-Forwarded-Proto";
          };
        };

        # extra cockpit modules
        environment.systemPackages = lib.mkIf config.services.cockpit.enable (
          (with pkgs; [
            kexec-tools
            libvirt-dbus
            virt-manager
          ])
          ++ (
            with self'.packages;
            [
              cockpit-benchmark
              # cockpit-docker TODO: fix this build?
              cockpit-file-sharing
              cockpit-machines
              cockpit-tailscale
            ]
            ++ lib.optional cfg.fs.zfs self'.packages.cockpit-zfs-manager
          )
        );
      };
  };
}
