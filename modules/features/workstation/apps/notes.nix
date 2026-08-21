{
  den.aspects.notes.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      tray = pkgs.fetchFromGitHub {
        owner = "redxtech";
        repo = "obsidian-tray";
        rev = "797e029bca480dcdb86d35ea618cca2c0b627cf8"; # add-second-instance-handler
        hash = "sha256-A/4d29kClP7SXGsSRRfSEEX2KtStrJ0AV1UonluHD5A=";
      };
      vault = {
        name = "Main";
        directory = "${config.xdg.userDirs.documents}/Obsidian";
      };
      vaultTarget = lib.removePrefix "${config.home.homeDirectory}/" "${vault.directory}/${vault.name}";
    in
    {
      # TODO: add proper configuration
      programs.obsidian = {
        enable = true;
        cli.enable = true;

        vaults.${vault.name} = {
          enable = true;
          target = vault.directory;
        };
      };

      home.file."${vaultTarget}/.obsidian/plugins/tray/main.js" = {
        force = true;
        source = "${tray}/main.js";
      };
    };
}
