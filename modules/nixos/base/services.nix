{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkDefault;
  cfg = config.base;
  cfgNet = config.network;
in {
  options.base.services = let
    inherit (lib) mkOption types;

    mkServiceOpt = name: {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable the ${name} service.";
      };
    };
  in {
    cockpit = mkServiceOpt "cockpit";
    earlyoom = mkServiceOpt "earlyoom";
    portainer = mkServiceOpt "portainer";
    startpage = mkServiceOpt "startpage";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers = let
      mkPorts = port: "${toString port}:${toString port}";
      mkData = name:
        "${config.users.users.${cfg.primaryUser}.home}/Documents/pod-config/"
        + name + ":/data";

      mkTLstr = name: "traefik.http.routers.${name}"; # make traefik label
      mkTLSstr = name:
        "traefik.http.services.${name}"; # make traefik router label

      mkLabels = name: {
        "traefik.enable" = "true";
        "${mkTLstr name}.rule" = "Host(`${name}.${cfgNet.address}`)";
        "${mkTLstr name}.entrypoints" = "websecure";
        "${mkTLstr name}.tls" = "true";
        "${mkTLstr name}.tls.certresolver" = "cloudflare";
      };
      mkLabelsPort = name: port:
        {
          "${mkTLSstr name}.loadbalancer.server.port" = "${toString port}";
        } // (mkLabels name);
    in {
      containers = {
        startpage = mkIf cfg.services.startpage.enable {
          image = "ghcr.io/redxtech/startpage";
          labels = mkLabels "startpage";
          ports = [ "9009:3000" ];
        };

        portainer = mkIf cfg.services.portainer.enable {
          image = "portainer/portainer-ee:latest";
          labels = mkLabelsPort "portainer" 9000;
          ports = [ "8000:8000" (mkPorts 9000) ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            (mkData "portainer")
          ];
          extraOptions = [ "--network" "host" ];
        };

        portainer-agent = mkIf cfg.services.portainer.enable {
          image = "portainer/agent:latest";
          ports = [ (mkPorts 9001) ];
          volumes = [
            "/var/lib/docker/volumes:/var/lib/docker/volumes"
            "/var/run/docker.sock:/var/run/docker.sock"
            "/:/host"
          ];
        };
      };
    };

    services.cockpit = mkIf cfg.services.cockpit.enable {
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

      port = mkDefault 9090;
      openFirewall = true;

      settings.WebService = {
        AllowUnencrypted = mkDefault true;
        ProtocolHeader = "X-Forwarded-Proto";
        Origins = mkDefault (lib.concatStringsSep " " [
          "http://localhost:9090"
          "ws://localhost:9090"
          "http://${cfg.hostname}:9090"
          "ws://${cfg.hostname}:9090"
          "https://${cfgNet.address}"
          "wss://${cfgNet.address}"
          "https://cockpit.${cfgNet.address}"
          "wss://cockpit.${cfgNet.address}"
        ]);
      };
    };

    services.earlyoom = mkIf cfg.services.earlyoom.enable {
      enable = true;
      enableNotifications = true;
    };
    systemd.oomd.enable = mkIf cfg.services.earlyoom.enable false;

    # extra cockpit modules
    environment.systemPackages = with pkgs;
      mkIf cfg.services.cockpit.enable [
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
