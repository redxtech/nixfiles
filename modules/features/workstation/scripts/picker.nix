{
  den.aspects.picker.homeManager =
    { config, lib, ... }:
    {
      programs.fuzzel = {
        enable = true;

        settings = {
          main.font =
            let
              fonts = config.stylix.fonts;
              size = "24";
            in
            lib.mkForce "${fonts.monospace.name}:size=${size}:weight=bold, Symbols Nerd Font:size=${size}";

          # re-enable if niri starts using uwsm
          # main.launch-prefix = "${pkgs.app2unit}/bin/app2unit --fuzzel-compat --";
        };
      };

      scripts.mainPicker = config.programs.fuzzel.package;
    };
}
