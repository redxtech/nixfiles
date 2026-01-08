{ config, lib, ... }:

let
  cfg = config.desktop;
  isHyprland = cfg.wm.hyprland.enable;
in {
  wayland.windowManager.hyprland = lib.mkIf isHyprland {
    settings = {
      windowrule = let
        inherit (lib) flatten optional;

        mkWindowRule2 = opts@{ class, title, ws, wsNum, ... }:
          let
            wrapSel = type: sel: "match:${type} (${sel})";
            sel = if opts.initialTitle != "" then
              wrapSel "initialTitle" opts.initialTitle
            else if title != "" && class != "" then
              "${wrapSel "class" class},${wrapSel "title" title}"
            else if title != "" then
              wrapSel "title" title
            else
              wrapSel "class" class;
            workspace = if (wsNum == null) then
              if ws == "*" then "unset" else "name:${ws}"
            else
              "${toString wsNum}";
            # all the rules
          in optional (workspace != "name:") "${sel},workspace ${workspace}"
          ++ optional opts.float "${sel},float on"
          ++ optional opts.tile "${sel},tile on"
          ++ optional opts.fullscreen "${sel},fullscreen on"
          ++ optional opts.psuedo "${sel},psuedo on"
          ++ optional opts.pin "${sel},pin on"
          ++ optional (!opts.follow) "${sel},no_initial_focus on"
          ++ optional (opts.size != "") "${sel},size ${opts.size}"
          ++ optional (opts.maxSize != "") "${sel},max_size ${opts.maxSize}"
          ++ optional (opts.opacity != "") "${sel},opacity ${opts.opacity}";

        rules = flatten (map mkWindowRule2 cfg.wm.rules);
      in [ "match:modal on, float on" ] ++ rules;

      layerrule = [
        "match:namespace notifications,blur on"
        "match:namespace launcher,blur on"
        "match:namespace launcher,dim_around on"
        "match:namespace launcher,blur_popups on"
        "match:namespace logout_dialog,blur on"
      ];
    };
  };
}
