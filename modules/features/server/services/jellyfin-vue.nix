{ self, ... }:

{
  den.aspects.jellyfin-vue.nixos =
    { config, host, ... }:
    let
      volumes = self.lib.server.volumes host.settings.server;
      port = 80;
      inherit (self.lib.containers) mkPort;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.jellyfin-vue = {
        image = "ghcr.io/jellyfin/jellyfin-vue:unstable";
        labels = mkAllLabels "jellyfin-vue" port {
          name = "jellyfin vue";
          group = "media";
          icon = "https://raw.githubusercontent.com/jellyfin/jellyfin-vue/refs/heads/master/frontend/public/icon.svg";
          href = "https://jellyfin-vue.${config.networking.fqdn}";
          desc = "jellyfin web ui";
          weight = -10;
        };
        environment = {
          DEFAULT_SERVERS = "https://jellyfin.${config.networking.fqdn}";
          HISTORY_ROUTER_MODE = "1";
        };
        ports = [ (mkPort 8099 port) ];
      };
    };
}
