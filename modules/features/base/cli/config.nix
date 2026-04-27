{
  den.aspects.cli-config = {
    homeManager =
      { config, pkgs, ... }:
      {
        xdg.configFile."ente/config.yaml".source =
          let
            settingsFormat = pkgs.formats.yaml { };
            settings.endpoint.api = "https://api.photos.super.fish";
          in
          settingsFormat.generate "config.yaml" settings;

        # TODO: enable when secrets are created

        # sops.secrets.streamrip = {
        #   sopsFile = ../../../../secrets/users/gabe/streamrip.yaml;
        #   path = "${config.xdg.configHome}/streamrip/config.toml";
        #   mode = "0740";
        # };
      };
  };
}
