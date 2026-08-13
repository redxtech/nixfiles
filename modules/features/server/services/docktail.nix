{ lib, self, ... }:

{
  den.aspects.docktail = {
    settings = {
      secretsFile = self.lib.server.mkSecretsFileOption "DockTail";

      serviceTags = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "tag:container" ];
        description = "Default Tailscale tags assigned to DockTail-managed services.";
      };
    };

    nixos =
      { config, host, ... }:
      let
        cfg = host.settings.docktail;
        docktailServiceNames = lib.filter (name: name != null) (
          lib.mapAttrsToList (
            _containerName: container: lib.attrByPath [ "labels" "docktail.service.name" ] null container
          ) config.virtualisation.oci-containers.containers
        );
        nativeServiceNames = removeAttrs config.network.finalServices docktailServiceNames;
      in
      {
        virtualisation.oci-containers.containers.docktail = {
          image = "ghcr.io/marvinvr/docktail:latest";
          environment = {
            DEFAULT_SERVICE_TAGS = lib.concatStringsSep "," cfg.serviceTags;
            # docktail otherwise treats every service in tailscaled as its own
            # and removes native routes during reconciliation and shutdown.
            IGNORE_SERVICE_NAMES = lib.concatStringsSep "," (lib.attrNames nativeServiceNames);
          };
          environmentFiles = [ config.sops.secrets.docktail_env.path ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock:ro"
            # keep the recreated socket visible across tailscaled restarts.
            "/var/run/tailscale:/var/run/tailscale"
          ];
        };

        systemd.services.docker-docktail = {
          after = [ "tailscaled.service" ];
          wants = [ "tailscaled.service" ];
        };

        sops.secrets.docktail_env.sopsFile = cfg.secretsFile;
      };
  };
}
