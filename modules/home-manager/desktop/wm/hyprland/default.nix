{ config, inputs, lib, pkgs, options, ... }:

let
  inherit (lib) mkIf strings;
  inherit (builtins) map;

  cfg = config.desktop.wm.hyprland;
  opt = options.desktop;
in {
  imports = [
    ./appearance.nix
    ./apps.nix
    ./binds.nix
    ./execs.nix
    ./notifs.nix
    ./rules.nix
    ./idle.nix
    ./locker.nix
  ];

  options.desktop.wm.hyprland = {
    enable = lib.mkEnableOption "enable hyprland config";

    inherit (opt.wm) binds;
    autostart = opt.autostart.run;
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # hyprland ecosystem
      hyprprop # xprop replacement
      hyprshade # blue light filter tool
      hyprsysteminfo # small gui for system info

      # tools
      clipman
      grimblast
      hyprpicker
      swww
      wev
      wl-clipboard
      wl-gammarelay-rs
      wlr-randr
    ];

    # hyprland configuration
    wayland.windowManager.hyprland = {
      enable = true;

      # use packages from nixos module
      package = null;
      portalPackage = null;

      settings = {
        "$mod" = "SUPER";

        input = {
          follow_mouse = 1;

          touchpad = {
            disable_while_typing = true;
            natural_scroll = true;
            middle_button_emulation = true;
            scroll_factor = 0.5;
            tap-to-click = true;
          };

          repeat_rate = 40;
          repeat_delay = 240;
          sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
        };

        cursor.no_warps = true;

        general = { layout = "dwindle"; };

        misc = {
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = true;
          focus_on_activate = true;
          enable_swallow = false;
          swallow_regex = "^(kitty|foot)$";
        };

        dwindle = {
          # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
          # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below;
          pseudotile = "yes";
          preserve_split = "yes"; # you probably want this
          force_split = 2;
        };

        master = {
          # See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
          new_on_top = false;
        };

        gestures = {
          # See https://wiki.hyprland.org/Configuring/Variables/ for more
          workspace_swipe = true;
        };

        monitor = let
          res = w: h: "${toString w}x${toString h}";
          pos = x: y: "${toString x}x${toString y}";
          mkMonitor = { name, height, width, rate, x, y, scale, ... }:
            "${name},${res width height}@${toString rate},${pos x y},${
              toString scale
            }";

          monitors = map mkMonitor config.desktop.monitors;
        in monitors
        # default for unknown monitors, place right of existing monitors
        ++ lib.singleton "monitor=,preferred,auto,1";

        workspace = let
          inherit (config.desktop) monitors;

          # generate workspace string
          mkWorkspace = monitor:
            { name, number, ... }:
            "${toString number},monitor:${monitor},defaultName:${name}";

          # get list of workspaces for a monitor
          mkMonitor = { name, workspaces, ... }:
            map (mkWorkspace name) workspaces;

          # convert specified monitor settings to hyprland workspace strings
          workspaces = lib.concatMap mkMonitor monitors;

        in workspaces;

        env = [
          "GRIMBLAST_EDITOR,satty"
          "MOZ_ENABLE_WAYLAND,1"
          "QT_QPA_PLATFORM,wayland"
          "XCURSOR_SIZE,32"
          "XDG_CURRENT_DESKTOP,hyprland"
          "XDG_SCREENSHOTS_DIR,~/Pictures/Screenshots"
          "SWWW_TRANSITION,wipe"
          "SWWW_TRANSITION_FPS,60"
          "SWWW_TRANSITION_STEP,2"
          "SWWW_TRANSITION_ANGLE,210"
        ];

        plugin = {
          hyprexpo = {
            columns = 3;
            gap_size = 15;
            bg_col = "rgb(${strings.removePrefix "#" config.user-theme.bg})";
            workspace_method = "first 1";

            gesture_fingers = 3;
            gesture_positive = false; # positive = down. negative = up.
          };
        };
      };

      plugins =
        with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system};
        [ hyprexpo ];

      systemd = {
        enable = false;

        # import systemd variables
        variables = [ "--all" ];
      };
    };

    # enable xsession
    xsession.enable = true;

    # set relevant desktop settings for hyprland
    desktop = {
      wallpaper.enable = true;
      wm.scripts.wm = {
        wallpaper = "${pkgs.swww}/bin/swww img";
        lock = "${pkgs.hyprlock}/bin/hyprlock";
        sleep =
          "${pkgs.coreutils}/bin/sleep 1 && ${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
      };
    };

    services.gammarelay.enable = true;
  };
}
