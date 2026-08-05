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
          entries = [ "${config.programs.spicetify.spicedSpotify}/share/applications/spotify.desktop" ];
        };

        # use niri to start these
        programs.niri.settings.spawn-at-startup =
          let
            runLater =
              cmds:
              [
                (lib.getExe' pkgs.coreutils "sleep")
                "5"
              ]
              ++ cmds;
          in
          [
            { argv = [ (lib.getExe' pkgs.nirius "niriusd") ]; }
            {
              argv = [
                (lib.getExe pkgs.sftpman)
                "mount_all"
              ];
            }
            { argv = runLater [ (lib.getExe pkgs.super-productivity) ]; }
            { argv = [ (lib.getExe pkgs.thunderbird) ]; } # TODO: look into birdtray
            { argv = [ (lib.getExe config.programs.obsidian.package) ]; }
          ];
      };
  };
}
