{ pkgs, ... }:

{
  imports = [
    ./binds.nix
    ./exec.nix
    ./rules.nix
    ./pypr.nix

    # ./waybar

    ../common
    ../bspwm/autorandr.nix
    ../bspwm/default-apps.nix
    ../bspwm/dunst.nix
    ../rofi

    ../wayland
  ];

  home.packages = with pkgs; [
    xdg-desktop-portal-hyprland

    hdrop
    grimblast
    scratchpad
    pyprland

    cliphist
    dunst
    swww
    pipewire
    wireplumber

    qt6.qtwayland
    libsForQt5.qt5.qtwayland
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    plugins = with pkgs;
      [
        # hyprbars
        hyprtrails
      ];

    settings = with pkgs; {
      monitor = [
        "${config.desktop.primaryMonitor},2560x1440,0x0,1"
        "${(builtins.elemAt config.desktop.monitors 1).name},2560x1440,2560x0,1"
      ];

      input = {
        # kb_layout = us
        # kb_options = caps:hyper,shift:both_capslock_cancel
        # kb_file = "$HOME/.config/xkb/hyper-caps-mod3.xkb";

        follow_mouse = 1;

        touchpad = { natural_scroll = "no"; };

        repeat_rate = 40;
        repeat_delay = 240;
        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
      };

      general = {
        gaps_in = 7;
        gaps_out = 10;
        border_size = 2;
        # "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.active_border" = "rgba(8be9fdee) rgba(6c71c4ee) 45deg";
        "col.inactive_border" = "rgba(073642aa)";

        layout = "dwindle";
      };

      misc = {
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        focus_on_activate = true;
        enable_swallow = false;
        swallow_regex = "^(kitty)$";
      };

      decoration = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more

        rounding = 0;

        drop_shadow = "yes";
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";

        blur = {
          enabled = "yes";
          size = 8;
          passes = 2;
          ignore_opacity = "yes";

        };
      };

      animations = {
        enabled = "yes";

        # Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more

        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";

        animation = [
          "windows, 1, 4, myBezier"
          "windowsOut, 1, 4, default, popin 80%"
          "border, 1, 8, default"
          "borderangle, 1, 6, default"
          "fade, 1, 4, default"
          "workspaces, 1, 4, default"
        ];

      };

      dwindle = {
        # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        pseudotile =
          "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below;
        preserve_split = "yes"; # you probably want this
        force_split = 2;
      };

      master = {
        # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        new_is_master = false;
      };

      gestures = {
        # See https://wiki.hyprland.org/Configuring/Variables/ for more
        workspace_swipe = "off";
      };

      # Example per-device config
      # See https://wiki.hyprland.org/Configuring/Keywords/#executing for more
      # "device:epic mouse V1" = { sensitivity = -0.5; };

      env = [
        "XCURSOR_SIZE,32"
        "GRIMBLAST_EDITOR,swappy"
        "XDG_SCREENSHOTS_DIR,~/Pictures/Screenshots"
        "SWWW_TRANSITION,wipe"
        "SWWW_TRANSITION_FPS,60"
        "SWWW_TRANSITION_STEP,2"
        "SWWW_TRANSITION_ANGLE,30"
      ];
    };
  };
}
