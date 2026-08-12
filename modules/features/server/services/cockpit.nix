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
        inherit (config.networking) fqdn hostName;
        inherit (host.settings.tailscale) tailnet;
        cfg = host.settings.base;
      in
      {
        network.services.cockpit = config.services.cockpit.port;

        services.cockpit = {
          enable = true;

          package = pkgs.cockpit.overrideAttrs (old: {
            # packagekit and selinux do not work on NixOS.
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
            "http://${hostName}:9090"
            "ws://${hostName}:9090"
            "https://${fqdn}"
            "wss://${fqdn}"
            "https://cockpit.${fqdn}"
            "wss://cockpit.${fqdn}"
            "https://cockpit.${tailnet}"
            "wss://cockpit.${tailnet}"
          ];

          settings.WebService = {
            AllowUnencrypted = true;
            ProtocolHeader = "X-Forwarded-Proto";
          };
        };

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
              cockpit-docker
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
