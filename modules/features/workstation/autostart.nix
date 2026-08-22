{
  den.aspects.autostart = {
    homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = with pkgs; [ dex ];

        xdg.autostart = {
          enable = true;
          entries =
            let
              getDesktop = package: desktopFile: "${package}/share/applications/${desktopFile}.desktop";
            in
            [
              (getDesktop config.programs.spicetify.spicedSpotify "spotify")
              (getDesktop pkgs.bitwarden-desktop "bitwarden")
            ];
        };

        # use niri to start these
        programs.niri.settings.spawn-at-startup = [
          { argv = [ (lib.getExe' pkgs.nirius "niriusd") ]; }
          {
            argv = [
              (lib.getExe pkgs.sftpman)
              "mount_all"
            ];
          }
          { argv = [ (lib.getExe config.programs.thunderbird.package) ]; }
          { argv = [ (lib.getExe config.programs.obsidian.package) ]; }
        ];
      };
  };
}
