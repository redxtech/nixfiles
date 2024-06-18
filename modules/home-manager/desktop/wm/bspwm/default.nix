{ pkgs, lib, config, options, ... }:

# TODO:
# - merge global binds with bspwm binds (extract bspwm only binds to own config)
# - guard all config with mkIf cfg.bspwm.enable option (or similar)

let
  cfg = config.desktop;
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

  in lib.mkIf (cfg.wm.wm == "bspwm") {
    home.packages = with pkgs; [ bspwm sxhkd ];

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

      rules = cfg.wm.rules;

      # some rules need to be set after the rest of the rules
      extraConfig = ''
        bspc rule -a 'firefox-aurora' --one-shot 'desktop=www'
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

    # use xdg-portal for opening files
    xdg.portal = {
      enable = true;

      extraPortals = with pkgs; [ xdg-desktop-portal ];
      xdgOpenUsePortal = true;

      config = { common.default = "*"; };
    };
  };
}
