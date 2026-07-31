{ self, ... }:

{
  den.aspects.calibre.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      inherit (self.lib.containers) mkPort mkPorts;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn)
        mkAllLabelsPort
        mkTLHstr
        mkTLRstr
        mkTLSstr
        ;
      headerLabel = header: "${mkTLHstr "calibre"}.customrequestheaders.${header}";
      secretMount = name: "${config.sops.secrets.${name}.path}:${config.sops.secrets.${name}.path}";
    in
    {
      virtualisation.oci-containers.containers.calibre = {
        image = "lscr.io/linuxserver/calibre:latest";
        labels =
          mkAllLabelsPort "calibre" 8804 {
            name = "calibre";
            group = "books";
            icon = "calibre.svg";
            href = "https://calibre.${config.networking.fqdn}";
            desc = "ebook manager";
            weight = -80;
          }
          // {
            "${mkTLSstr "calibre"}.loadbalancer.serverstransport" = "ignorecert@file";
            "${mkTLSstr "calibre"}.loadbalancer.server.scheme" = "https";
            "${mkTLRstr "calibre"}.middlewares" = "calibre@docker";
            "${headerLabel "Cross-Origin-Embedder-Policy"}" = "require-corp";
            "${headerLabel "Cross-Origin-Opener-Policy"}" = "same-origin";
            "${headerLabel "Cross-Origin-Resource-Policy"}" = "same-site";
          };
        environment =
          self.lib.server.defaultEnvironment {
            uid = server.uid;
            gid = server.gid;
            timeZone = config.time.timeZone;
          }
          // {
            FILE__CUSTOM_USER = config.sops.secrets.calibre_user.path;
            FILE__PASSWORD = config.sops.secrets.calibre_pw.path;
            CUSTOM_PORT = "8805";
            CUSTOM_HTTPS_PORT = "8804";
          };
        ports = [
          (mkPorts 8805)
          (mkPorts 8804)
          (mkPorts 8808)
          (mkPort 8806 8081)
        ];
        volumes = [
          ((self.lib.server.volumes server).config "calibre")
          (secretMount "calibre_user")
          (secretMount "calibre_pw")
        ];
      };

      networking.firewall.allowedTCPPorts = [ 8808 ];
      sops.secrets = {
        calibre_user.sopsFile = server.legacySopsFile;
        calibre_pw.sopsFile = server.legacySopsFile;
      };
    };
}
