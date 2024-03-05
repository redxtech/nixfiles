{ inputs, pkgs, lib, config, ... }:

{
  desktop = {
    wm = {
      rules = [
        {
          window = "firefox-aurora:*:Library";
          state = "floating";
        }
        {
          window = "discord";
          workspace = "chat";
          flags.follow = false;
        }
        {
          window = "Spotify";
          workspace = "music";
        }
        {
          window = "obsidian";
          state = "floating";
          workspace = 4;
        }
        {
          window = "Plex";
          workspace = "video";
        }
        {
          window = "plexmediaplayer";
          workspace = "video";
        }
        {
          window = "Slack";
          state = "floating";
        }
        {
          window = "Element";
          workspace = "chat";
          flags.follow = false;
        }
        {
          window = "Plexamp";
          state = "floating";
        }
        {
          window = "Subl";
          workspace = "*";
        }
        {
          window = "flameshot";
          state = "floating";
        }
        {
          window = "Blueman-manager";
          state = "floating";
        }
        {
          window = "mpv:*:Webcam";
          state = "floating";
        }
        {
          window = "mplayer2";
          state = "floating";
        }
        {
          window = "Yad";
          state = "floating";
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
        "${spotifywm}/bin/spotifywm"
        "${xfce.thunar}/bin/thunar --daemon"
        "${obsidian}/bin/obsidian"
        "${solaar}/bin/solaar -w hide"
      ];
      runOnceNoF = [ "${variety}/bin/variety" ];
      runFloat = [ "${kitty}/bin/kitty ${btop}/bin/btop" ];
      runDays = [{
        cmd = "${slack}/bin/slack";
        days = [ 0 1 2 3 4 ];
      }];
    };
  };
}
