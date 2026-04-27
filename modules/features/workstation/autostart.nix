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
          entries = with pkgs; [
            # "${config.programs.spicetify.spicedSpotify}/share/applications/spotify.desktop"
          ];
        };

        # use niri to start these
        programs.niri.settings.spawn-at-startup = [
          {
            argv = [
              (lib.getExe pkgs.sftpman)
              "mount_all"
            ];
          }
        ];
      };
  };
}
