{ self, ... }:

{
  den.aspects.calibre.settings.secretsFile = self.lib.server.mkSecretsFileOption "Calibre";

  den.aspects.calibre.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
      httpPort = 8805;
      httpsPort = 8804;
      inherit (self.lib.containers) mkPort mkPorts;
      inherit (self.lib.containers.labels) mkTailscaleLabels;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn)
        mkAllLabels
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
          mkAllLabels "calibre" httpsPort {
            name = "calibre";
            group = "books";
            icon = "calibre.svg";
            href = "https://calibre.${config.networking.fqdn}";
            desc = "ebook manager";
            weight = -80;
          }
          // mkTailscaleLabels "calibre" httpPort
          // {
            "${mkTLSstr "calibre"}.loadbalancer.serverstransport" = "ignorecert@file";
            "${mkTLSstr "calibre"}.loadbalancer.server.scheme" = "https";
            "${mkTLRstr "calibre"}.middlewares" = "tinyauth@file,calibre@docker";
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
            CUSTOM_PORT = toString httpPort;
            CUSTOM_HTTPS_PORT = toString httpsPort;
          };
        ports = [
          (mkPorts httpPort)
          (mkPorts httpsPort)
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
        calibre_user.sopsFile = host.settings.calibre.secretsFile;
        calibre_pw.sopsFile = host.settings.calibre.secretsFile;
      };
    };
}
