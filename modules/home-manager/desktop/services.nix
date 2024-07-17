{ config, lib, pkgs, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    services = {
      blueman-applet.enable = true;

      flameshot.enable = false;

      keybase = { enable = false; };
      megasync = { enable = false; };

      network-manager-applet.enable = true;
      plex-mpv-shim.enable = true;

      playerctld.enable = true;
      # redshift.enable = false;

      signaturepdf = {
        enable = true;
        port = 9008;
      };

      spotifyd = {
        enable = false;

        settings = {
          global = {
            username = "redxtech";
            password_cmd =
              "${pkgs.coreutils}/bin/cat ${config.xdg.configHome}/spotify-tui/spotify.txt";

            use_mpris = true;
            backend = "pulseaudio";

            device_type = "computer";
            device_name = "desktop-spotifyd";

            bitrate = 320;
          };
        };
      };

      kdeconnect = lib.mkIf cfg.kdeConnect {
        enable = true;
        indicator = true;
      };
    };

    # hide all desktop entries, except for org.kde.kdeconnect.settings
    xdg.desktopEntries = lib.mkIf cfg.kdeConnect {
      "org.kde.kdeconnect.sms" = {
        exec = "";
        name = "KDE Connect SMS";
        settings.NoDisplay = "true";
      };
      "org.kde.kdeconnect.nonplasma" = {
        exec = "";
        name = "KDE Connect Indicator";
        settings.NoDisplay = "true";
      };
      "org.kde.kdeconnect.app" = {
        exec = "";
        name = "KDE Connect";
        settings.NoDisplay = "true";
      };
    };
  };
}
