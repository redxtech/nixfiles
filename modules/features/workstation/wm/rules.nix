{ inputs, self, ... }:

{
  den.aspects.window-manager-rules.homeManager = {
    programs.niri.settings = {
      window-rules = [
        {
          background-effect = {
            blur = true;
            xray = false;
          };
        }
        {
          matches = [ { app-id = "firefox-nightly"; } ];
          open-focused = true;
          default-column-width.proportion = 1.0;
          open-maximized-to-edges = false;
        }
        {
          matches = [
            { app-id = "discord"; }
            { app-id = "vesktop"; }
            { app-id = "equibop"; }
            { app-id = "legcord"; }
          ];
          open-on-workspace = "chat";
          open-focused = false;
          default-column-width.proportion = 1.0;
          open-maximized-to-edges = false;
        }
        {
          matches = [ { app-id = "Element"; } ];
          open-on-workspace = "chat";
        }
        {
          matches = [
            { app-id = "thunderbird"; }
            { app-id = "eu.betterbird.Betterbird"; }
          ];
          open-on-workspace = "chat";
        }
        {
          matches = [ { app-id = "spotify"; } ];
          open-on-workspace = "music";
          open-focused = false;
          default-column-width.proportion = 1.0;
          open-maximized-to-edges = false;
        }

        {
          matches = [
            {
              app-id = "mpv";
              title = "Webcam";
            }
          ];
          open-floating = true;
        }

        {
          matches =
            let
              match = app-id: {
                inherit app-id;
                is-focused = false;
              };
            in
            map match [
              "nemo"
              "thunar"
              "nautilus"
              "dolphin"
            ];
          opacity = 0.9;
        }

        # noctalia settings
        {
          matches = [ { app-id = "dev.noctalia.Noctalia"; } ];
          open-floating = true;
        }

        # indicate screencasted windows with red colors.
        {
          matches = [ { is-window-cast-target = true; } ];
          border.inactive.color = "#7d0d2d";
          shadow.color = "#7d0d2d70";
          focus-ring = {
            enable = true;
            active.color = "#f38ba8";
            inactive.color = "#7d0d2d";
          };
          tab-indicator = {
            active.color = "#f38ba8";
            inactive.color = "#7d0d2d";
          };
        }

        # steam stuff
        {
          matches = [ { app-id = "gamescope"; } ];
          open-fullscreen = true;
        }

        # steam notifications: https://niri-wm.github.io/niri/Application-Issues.html#steam
        {
          matches = [
            {
              app-id = "steam";
              title = "^notificationtoasts_\\d+_desktop$";
            }
          ];
          default-floating-position = {
            x = 10;
            y = 10;
            relative-to = "bottom-right";
          };
          open-focused = false;
        }

        # TODO: add bitwarden window rule/script

        # TODO: these rules need to be tested
        {
          matches = [
            {
              app-id = "firefox-nightly";
              title = "Enter name of file to save to...";
            }
            {
              title = "File Upload.*";
            }
          ];
          open-floating = true;
        }
        {
          matches = [ { title = "Picture.in.Picture"; } ];
          open-floating = true;
          # TODO: figure out how to make the window pinned/sticky
        }
      ]
      ++ (map
        (app-id: {
          matches = [ { inherit app-id; } ];
          open-floating = true;
          default-window-height.fixed = 700;
          default-column-width.fixed = 1200;
        })
        [
          "footclient_float"
          "kitty_float"
          "obsidian"
          "org.pulseaudio.pavucontrol"
          "pavucontrol"
          "pwvucontrol"
          ".piper-wrapped"
          ".blueman-manager-wrapped"
        ]
      );

      layer-rules = [
        {
          matches = [ { namespace = "^noctalia-(background|launcher-overlay|dock)-.*$"; } ];
          background-effect.xray = false;
        }
        {
          matches = [ { namespace = "^launcher$"; } ];
          background-effect.blur = true;
        }
        {
          matches = [ { namespace = "^noctalia-backdrop"; } ];
          place-within-backdrop = true;
        }
      ];
    };
  };
}
