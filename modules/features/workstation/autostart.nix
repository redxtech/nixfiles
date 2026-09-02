{
  den.aspects.autostart = {
    homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        # some apps need to wait until the tray is ready before starting
        mkTrayAutostartService =
          {
            name,
            description,
            execStart,
          }:
          lib.nameValuePair name {
            Unit = {
              Description = description;
              After = [ "noctalia.service" ];
              Wants = [ "noctalia.service" ];
              PartOf = [ "graphical-session.target" ];
            };

            Service = {
              ExecStartPre = "${lib.getExe' pkgs.glib "gdbus"} wait --session org.kde.StatusNotifierWatcher";
              ExecStart = execStart;
              Restart = "on-failure";
              TimeoutStartSec = "30s";
            };

            Install.WantedBy = [ "graphical-session.target" ];
          };

        trayAutostartApps = [
          {
            name = "bitwarden";
            description = "Bitwarden";
            execStart = lib.getExe pkgs.bitwarden-desktop;
          }
          {
            name = "super-productivity";
            description = "Super Productivity";
            execStart = "${lib.getExe pkgs.flatpak} run com.super_productivity.SuperProductivity";
          }
        ];
      in
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
            ];
        };

        systemd.user.services = builtins.listToAttrs (map mkTrayAutostartService trayAutostartApps);

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
