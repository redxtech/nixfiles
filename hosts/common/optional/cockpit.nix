{ config, lib, pkgs, ... }:

{
  services.cockpit = {
    enable = true;

    package = pkgs.cockpit.overrideAttrs (old: {
      postBuild = ''
        ${old.postBuild}

        rm -rf \
          dist/packagekit \
          dist/selinux
      '';
    });

    port = lib.mkDefault 9090;
    openFirewall = true;

    settings = {
      WebService = {
        AllowUnencrypted = true;
        Origins = lib.concatStringsSep " " [
          "https://${config.nas.domain}"
          "wss://${config.nas.domain}"
          "http://quasar:${toString config.nas.ports.cockpit}"
          "ws://quasar:${toString config.nas.ports.cockpit}"
        ];
        ProtocolHeader = "X-Forwarded-Proto";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    cockpit-benchmark
    cockpit-docker
    cockpit-file-sharing
    cockpit-machines
    cockpit-tailscale
    libvirt-dbus
    virt-manager
  ];

  services.traefik.dynamicConfigOptions.http =
    lib.mkIf config.services.traefik.enable {
      routers.cockpit = {
        rule = "Host(`${config.nas.domain}`)";
        service = "cockpit";
        entrypoints = [ "websecure" ];
      };
      services.cockpit.loadBalancer.servers =
        [{ url = "http://localhost:${toString config.nas.ports.cockpit}"; }];
    };
}
