{ config, lib, ... }:

let cfg = config.desktop;
in {
  wayland.windowManager.hyprland = {
    settings = {
      windowrulev2 = let
        inherit (lib) flatten optional;

        mkWindowRule2 = opts@{ class, title, ws, ... }:
          let
            wrapSel = type: sel: "${type}:(${sel})";
            sel = if opts.initialTitle != "" then
              wrapSel "initialTitle" opts.initialTitle
            else if title != "" && class != "" then
              "${wrapSel "class" class},${wrapSel "title" title}"
            else if title != "" then
              wrapSel "title" title
            else
              wrapSel "class" class;
            workspace = if ws == "*" then "unset" else "name:${ws}";
          in ([ ] # all the rules
            ++ optional (ws != "") "workspace ${workspace},${sel}"
            ++ optional (opts.float) "float,${sel}"
            ++ optional (opts.tile) "tile,${sel}"
            ++ optional (opts.fullscreen) "fullscreen,${sel}"
            ++ optional (opts.psuedo) "psuedo,${sel}"
            ++ optional (opts.pin) "pin,${sel}"
            ++ optional (!opts.follow) "noinitialfocus,${sel}"
            ++ optional (opts.maxSize != "") "maxsize ${opts.maxSize},${sel}"
            ++ optional (opts.opacity != "") "opacity ${opts.opacity},${sel}");

        rules = flatten (map mkWindowRule2 cfg.wm.rules);
      in rules;

      layerrule = [
        "blur,waybar"
        "blur,notifications"
        "ignorezero,notifications"
        "blur,launcher"
        "dimaround,launcher"
        "blurpopups,launcher"
        "blur,logout_dialog"
      ];
    };
  };
}
