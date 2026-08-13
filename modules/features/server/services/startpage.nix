{ self, ... }:

{
  den.aspects.startpage.nixos =
    { config, ... }:
    let
      port = 3000;
      inherit (self.lib.containers.labels.traefik config.networking.fqdn) mkAllLabels;
    in
    {
      virtualisation.oci-containers.containers.startpage = {
        image = "ghcr.io/redxtech/startpage";
        labels = mkAllLabels "startpage" port {
          name = "startpage";
          group = "utils";
          icon = "https://raw.githubusercontent.com/redxtech/excalith-start-page/master/public/icon.svg";
          href = "https://startpage.${config.networking.fqdn}";
          desc = "custom startpage";
        };
        ports = [ "9009:${toString port}" ];
      };
    };
}
