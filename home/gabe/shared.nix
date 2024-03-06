{ inputs, pkgs, lib, config, ... }:

{
  desktop = {
    wm = {
      rules = [
        {
          window = "firefox-aurora:*:Library";
          flags.state = "floating";
        }
        {
          window = "discord";
          flags.workspace = "chat";
          flags.follow = false;
        }
        {
          window = "Spotify";
          flags.workspace = "music";
        }
        {
          window = "obsidian";
          flags.state = "floating";
          flags.workspace = 4;
        }
        {
          window = "Plex";
          flags.workspace = "video";
        }
        {
          window = "plexmediaplayer";
          flags.workspace = "video";
        }
        {
          window = "Slack";
          flags.state = "floating";
        }
        {
          window = "Element";
          flags.workspace = "chat";
          flags.follow = false;
        }
        {
          window = "Plexamp";
          flags.state = "floating";
        }
        {
          window = "Subl";
          flags.workspace = "*";
        }
        {
          window = "flameshot";
          flags.state = "floating";
        }
        {
          window = "Blueman-manager";
          flags.state = "floating";
        }
        {
          window = "mpv:*:Webcam";
          flags.state = "floating";
        }
        {
          window = "mplayer2";
          flags.state = "floating";
        }
        {
          window = "Yad";
          flags.state = "floating";
        }
        {
          window = "Screenkey";
          flags.manage = false;
        }
      ];

      binds = [
        {
          keys = "super + Return";
          command = "kitty";
          description = "Launch terminal";
        }
        {
          keys = "super + shift + Return";
          command = "kitty";
          description = "Launch floating terminal";
        }
      ];

      bspwm = {
        autostart = with pkgs; [
          "${config.home.homeDirectory}/.fehbg"
          "${xorg.xset}/bin/xset r rate 240 40" # keyboard repeat rate
          "${xorg.xset}/bin/xset s off -dpms" # disable screen blanking
          "${xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr"
        ];
      };
    };

    autostart = with pkgs; {
      run = [
        "${sftpman}/bin/sftpman mount_all"
        "${gnupg}/bin/gpgconf --launch gpg-agent"
      ];
      runOnce = [
        "${networkmanagerapplet}/bin/nm-applet --indicator"
        "${blueman}/bin/blueman-applet"
        "${flameshot}/bin/flameshot"
        "${discord}/bin/discord"
        "${spotifywm}/bin/spotify"
        "${xfce.thunar}/bin/thunar --daemon"
        "${solaar}/bin/solaar -w hide"
      ];
      runOnceNoF = [ "${variety}/bin/variety" ];
      runWithRule = [{
        cmd = "${kitty}/bin/kitty ${btop}/bin/btop";
        window = "kitty";
        flags = {
          state = "floating";
          workspace = "r-www";
        };
      }];
      runDays = [{
        cmd = "${slack}/bin/slack";
        days = [ 0 1 2 3 4 ];
      }];
    };
  };
}
