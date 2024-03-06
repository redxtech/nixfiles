{ lib, config, pkgs, ... }: {
  imports = [
    ../common

    ./default-apps.nix
    ./dunst.nix
    ./picom.nix
    ./polybar
    ../rofi
    ./services.nix
    ./sxhkd.nix
  ];

  home.packages = with pkgs; [ ];

  xsession = {
    enable = true;

    windowManager.bspwm = with builtins; {
      enable = true;

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
    };
  };
}
