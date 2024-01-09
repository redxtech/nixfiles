{ config, pkgs, lib, ... }:

{
  services = {
    blueman-applet = { enable = false; };

    easyeffects.enable = false;

    flameshot = { enable = false; };

    keybase = { enable = false; };
    megasync = { enable = false; };
    network-manager-applet = { enable = false; };
    plex-mpv-shim = { enable = false; };

    playerctld = { enable = true; };
    redshift = { enable = false; };

    signaturepdf = {
      enable = true;
      port = 9008;
    };

    spotifyd = {
      enable = true;

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
  };

  systemd.user.services = {
    setxmodmap = {
      Unit = {
        Description = "Set up keyboard in X";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart =
          "${pkgs.xorg.xmodmap}/bin/xmodmap ${config.home.homeDirectory}/.Xmodmap";
      };
    };

    xplugd-xmodmap = {
      Unit = {
        Description = "Rerun setxmodmap.service when I/O is changed";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Type = "forking";
        ExecStart = let
          script = pkgs.writeShellScript "xplugrc" ''
            case "$1,$3" in
              keyboard,connected)
              systemctl --user restart setxmodmap.service
              ;;
            esac
          '';
        in "${pkgs.xplugd}/bin/xplugd ${script}";
      };
    };
  };
}
