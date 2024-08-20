{ pkgs, lib, config, options, ... }:

# TODO:
# - merge global binds with bspwm binds (extract bspwm only binds to own config)
# - guard all config with mkIf cfg.bspwm.enable option (or similar)

let
  cfg = config.desktop;
  wm = cfg.wm.bspwm;
  opt = options.desktop;
in {
  imports = [ ./autolock.nix ./dunst.nix ./picom.nix ];

  options.desktop.wm.bspwm = {
    enable = lib.mkEnableOption "enable bspwm config";

    binds = opt.wm.binds;
    autostart = opt.autostart.run;
  };

  config = let
    inherit (lib) mkDefault attrsToList;
    inherit (lib.strings) concatStringsSep concatMapStringsSep;
    inherit (builtins) listToAttrs map toString;

    foldWs = workspaces: (map (ws: ws.name) workspaces);
    mkMonitor = { name, workspaces, ... }: {
      name = name;
      value = foldWs workspaces;
    };
    monitorsWS = listToAttrs (map mkMonitor cfg.monitors);
    flatMonitors = concatStringsSep " " (map (m: m.name) cfg.monitors);

    fmtFlags = flags:
      concatStringsSep " " (map ({ name, value }:
        (if name == "workspace" then
          "'desktop=${toString value}'"
        else
          "'${name}=${toString value}'")) (attrsToList flags));

    runWithRule = { cmd, window, flags }:
      "${pkgs.bspwm}/bin/bspc rule --add ${window} --one-shot ${
        fmtFlags flags
      } && ${cmd}";

  in lib.mkIf wm.enable {
    home.packages = with pkgs; [ bspwm sxhkd xclip xdragon ];

    xsession.enable = true;

    xsession.windowManager.bspwm = {
      enable = true;

      settings = {
        border_width = mkDefault 2;
        window_gap = mkDefault 12;
        split_ratio = mkDefault 0.52;
        borderless_monocle = mkDefault true;
        gapless_monocle = mkDefault true;
        focus_follows_pointer = mkDefault true;
        pointer_follows_focus = mkDefault false;

        # theme
        # TODO: localize theme config to its own module
        normal_border_color = mkDefault "#073642";
        active_border_color = mkDefault "#073642";
        focused_border_color = mkDefault "#6c71c4";
      };

      rules = let
        inherit (lib) mkIf;
        mkRule = opts@{ class, title, ws, ... }:
          let
            sel = if title == "" then
              class
            else
              "${if class == "" then "*" else class}:*:${title}";
          in {
            name = sel;
            value = {
              desktop = mkIf (ws != "") ws;
              state = if opts.float then
                "floating"
              else if opts.fullscreen then
                "fullscreen"
              else if opts.psuedo then
                "psuedo_tiled"
              else
                "tiled";
              sticky = mkIf (opts.pin) opts.pin;
              follow = mkIf (!opts.follow) false;
              manage = mkIf (!opts.manage) false;
            };
          };
      in lib.listToAttrs (map mkRule cfg.wm.rules);

      # some rules need to be set after the rest of the rules
      # TODO: use new rule.oneShot option
      extraConfig = ''
        bspc rule -a 'firefox-nightly' --one-shot 'desktop=www'
        bspc rule -a '*:*:Open Files' 'desktop=*' 'state=floating'
        bspc rule -a '*:*:File Upload' 'desktop=*' 'state=floating'
        bspc rule -a '*:*:Picture in picture' 'state=floating'
        bspc rule -a '*:*:Picture-in-picture' 'state=floating'
        bspc rule -a '*:*:Picture-in-Picture' 'state=floating'
      '';

      monitors = monitorsWS;

      startupPrograms = [
        "${pkgs.bspwm}/bin/bspc wm --reorder-monitors ${flatMonitors}"
        "${config.home.homeDirectory}/.fehbg"
        "${pkgs.flameshot}/bin/flameshot"
      ] ++ cfg.autostart.processed # global autostart commands
        ++ (map runWithRule
          cfg.autostart.runWithRule); # autostart commands with rules
    };

    services.sxhkd = let
      entryToBind = { description, cmd, keys, ... }: (''
        # ${description}
        ${concatMapStringsSep "\n" (bind: ''
          ${bind}
          	${cmd}'') keys}
      '');

      keybindingsStr = concatStringsSep "\n" (map entryToBind cfg.wm.binds);
    in {
      enable = true;
      extraConfig = ''
        ${keybindingsStr}
      '';
    };

    xdg.configFile."sxhkd/cheatcheet".text = let
      entryToCheatSheet = { description, cmd, keys, ... }: (''
        ${concatMapStringsSep "\n" (bind: "${bind} => ${description} => ${cmd}")
        keys}
      '');

      cheatsheetStr =
        concatStringsSep "\n" (map entryToCheatSheet cfg.wm.binds);
    in cheatsheetStr;

    # set relevant desktop settings for bspwm
    desktop = {
      wallpaper.enable = true;
      wm.scripts.wm = {
        wallpaper = "${pkgs.feh}/bin/feh --bg-fill";
        lock = "${pkgs.betterlockscreen}/bin/betterlockscreen --lock dimblur";
        sleep =
          "${pkgs.coreutils}/bin/sleep 1 && ${pkgs.xorg.xset}/bin/xset dpms force off";
      };
    };

    systemd.user.services = {
      gpaste = {
        Unit = {
          Description = "Start gpaste daemon";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };

        Service = {
          Type = "dbus";
          BusName = "org.gnome.GPaste";
          ExecStart = "${pkgs.gpaste}/libexec/gpaste/gpaste-daemon";
        };
      };
    };

    # use xdg-portal for opening files
    xdg.portal = {
      enable = true;

      extraPortals = with pkgs; [ xdg-desktop-portal ];
      xdgOpenUsePortal = true;

      config.common.default = "*";
    };
  };
}
