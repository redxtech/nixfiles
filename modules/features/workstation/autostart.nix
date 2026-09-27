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
        cfg = config.workstation.autostart;

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
              PartOf = [ "graphical-session.target" ];
            };

            Service = {
              ExecStartPre = "${lib.getExe' pkgs.glib "gdbus"} wait --session org.kde.StatusNotifierWatcher";
              ExecStart = execStart;
              Restart = "on-failure";
              TimeoutStartSec = "30s";
            };

            Install.WantedBy = [ "noctalia.service" ];
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
        options.workstation.autostart = {
          networkMounts = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to mount remote filesystems at graphical login.";
          };

          spotify = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to start Spotify at graphical login.";
          };

          thunderbird = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to start Thunderbird at graphical login.";
          };
        };

        config = {
          home.packages = with pkgs; [ dex ];

          xdg.autostart = {
            enable = true;
            entries = lib.optionals cfg.spotify (
              let
                getDesktop = package: desktopFile: "${package}/share/applications/${desktopFile}.desktop";
              in
              [
                (getDesktop config.programs.spicetify.spicedSpotify "spotify")
              ]
            );
          };

          systemd.user.services = builtins.listToAttrs (map mkTrayAutostartService trayAutostartApps);

          # use niri to start these
          programs.niri.settings.spawn-at-startup = [
            { argv = [ (lib.getExe' pkgs.nirius "niriusd") ]; }
            { argv = [ (lib.getExe config.programs.obsidian.package) ]; }
          ]
          ++ lib.optional cfg.networkMounts {
            argv = [
              (lib.getExe pkgs.sftpman)
              "mount_all"
            ];
          }
          ++ lib.optional cfg.thunderbird {
            argv = [ (lib.getExe config.programs.thunderbird.package) ];
          };
        };
      };
  };
}
