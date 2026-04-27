{ inputs, self, ... }:

{
  den.aspects.screenshot = {
    homeManager =
      { config, pkgs, ... }:
      {
        home.packages = with pkgs; [ wayshot ];

        xdg.configFile."wayshot/config.toml".source =
          let
            settingsFormat = pkgs.formats.toml { };
            settingsFile = settingsFormat.generate "config.toml" {
              base = {
                cursor = true;
                freeze = true;
                clipboard = true;
                stdout = true;
              };
              file = {
                path = "${config.xdg.userDirs.pictures}/screenshots/%Y";
                name_format = "%Y_%m_%d-%H_%M_%S";
                format = "png";
              };
            };
          in
          settingsFile;
      };
  };
}
