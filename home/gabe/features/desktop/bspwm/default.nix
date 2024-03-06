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

  # window resizing data for jgmenu
  xdg.configFile."bspwm/resize-aspect.csv".text =
    let resize-aspect = pkgs.callPackage ./polybar/scripts/resize-aspect { };
    in ''
      16x9,${resize-aspect}/bin/resize-aspect 16 9
      4x3,${resize-aspect}/bin/resize-aspect 4 3
      21x9,${resize-aspect}/bin/resize-aspect 12 5
      Balance,${pkgs.bspwm}/bin/bspc node @parent -r .5
    '';
}
