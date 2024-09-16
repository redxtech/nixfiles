{ config, pkgs, lib, ... }:

let
  cfg = config.nas;
  cfgNet = config.network;
  mkConf = name: cfg.paths.config + "/" + name;

  nativeMass = config.services.music-assistant.enable;

  inherit (lib) mkIf;
in {
  config = {
    network.services.mass = mkIf nativeMass 8095;

    virtualisation.oci-containers.containers.mass = let
      mkPort = host: guest: "${toString host}:${toString guest}";
      mkPorts = port: mkPort port port;
      mkTLRstr = name: "traefik.http.routers.${name}";
      mkLabels = name: {
        "traefik.enable" = "true";
        "${mkTLRstr name}.rule" = "Host(`${name}.${cfgNet.address}`)";
        "${mkTLRstr name}.entrypoints" = "websecure";
        "${mkTLRstr name}.tls" = "true";
        "${mkTLRstr name}.tls.certresolver" = "cloudflare";
      };
    in mkIf (!nativeMass) {
      image = "ghcr.io/music-assistant/server:latest";
      labels = mkLabels "mass" // {
        "traefik.http.services.mass.loadbalancer.server.port" = "8095";
      };
      ports = [ (mkPorts cfg.ports.music-assistant) (mkPorts 8097) ];
      volumes = [
        "${cfg.paths.config}/music-assistant-server:/data"
        "${cfg.paths.media}:/media"
      ];
      extraOptions = [ "--privileged" "--network" "host" ];
    };

    services.music-assistant = {
      enable = false;
      # package = pkgs.python-music-assistant;

      extraOptions = [ "--config" (mkConf "music-assistant") ];

      providers = [
        "chromecast"
        # "hass" # TODO: enable when updating nixpkgs
        "jellyfin"
        "plex"
        "soundcloud"
        "spotify"
        "ytmusic"
      ];
    };

    users.groups.mass = mkIf nativeMass { };
    users.users.mass = mkIf nativeMass {
      isSystemUser = true;
      group = config.users.groups.mass.name;
    };
    systemd.services.music-assistant.serviceConfig = mkIf nativeMass {
      DynamicUser = lib.mkForce false;
      User = "mass";
      Group = config.users.users.mass.group;
    };

    networking.firewall.allowedTCPPorts = [ 8095 8097 ];
  };
}
