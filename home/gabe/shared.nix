{ inputs, pkgs, lib, config, ... }:

{
  desktop = {
    wm = {
      rules = {
        "firefox-aurora:*:Library" = { state = "floating"; };
        discord = {
          desktop = "chat";
          follow = false;
        };
        Spotify = { desktop = "music"; };
        obsidian = {
          desktop = "^4";
          state = "floating";
        };
        Plex = { desktop = "video"; };
        plexmediaplayer = { desktop = "video"; };
        Slack = { state = "floating"; };
        Element = {
          desktop = "chat";
          follow = false;
        };
        Plexamp = { state = "floating"; };
        Subl = { desktop = "*"; };
        flameshot = { state = "floating"; };
        "Blueman-manager" = { state = "floating"; };
        "mpv:*:Webcam" = { state = "floating"; };
        "Kupfer.py" = { focus = true; };
        mplayer2 = { state = "floating"; };
        Screenkey = { manage = false; };
        Yad = { state = "floating"; };
      };

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
