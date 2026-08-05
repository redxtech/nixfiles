{ self, ... }:

{
  den.aspects.beszel.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers = {
        beszel = {
          image = "henrygd/beszel:latest";
          labels = mkAllLabels "beszel" {
            name = "beszel";
            group = "monitoring";
            icon = "beszel.svg";
            href = "https://beszel.${config.networking.fqdn}";
            desc = "docker monitoring";
            weight = -70;
            widget = {
              type = "beszel";
              url = "http://${config.networking.hostName}:8090";
              username = "{{HOMEPAGE_VAR_BESZEL_USER}}";
              password = "{{HOMEPAGE_VAR_BESZEL_PASS}}";
              systemId = "{{HOMEPAGE_VAR_BESZEL_SYSTEMID}}";
              version = "2";
            };
          };
          environment.APP_URL = "https://beszel.${config.networking.fqdn}";
          ports = [ (mkPorts 8090) ];
          volumes = [ "${server.configRoot}/beszel:/beszel_data" ];
        };

        beszel-agent = {
          image = "henrygd/beszel-agent:latest";
          environment = {
            LISTEN = "/beszel_socket/beszel.sock";
            HUB_URL = "http://localhost:8090";
          };
          environmentFiles = [ config.sops.secrets.beszel_env.path ];
          volumes = [
            "${server.configRoot}/beszel-agent:/var/lib/beszel-agent"
            "${server.configRoot}/beszel-agent/beszel_socket:/beszel_socket"
            "/var/run/docker.sock:/var/run/docker.sock:ro"
          ];
          networks = [ "host" ];
        };
      };

      sops.secrets.beszel_env.sopsFile = ../../../../secrets/hosts/quasar/containers.yaml;
    };
}
