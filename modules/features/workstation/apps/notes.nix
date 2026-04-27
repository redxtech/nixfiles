{
  den.aspects.notes.homeManager =
    { config, ... }:
    {
      # TODO: add proper configuration
      programs.obsidian = {
        enable = true;
        cli.enable = true;

        vaults.Main = {
          enable = true;
          target = config.xdg.userDirs.documents + "/Obsidian";
        };

        # defaultSettings = { };
      };
    };
}
