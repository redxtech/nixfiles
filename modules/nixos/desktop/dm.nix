{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf optionals;
  cfg = config.desktop;
in {
  options.desktop = let inherit (lib) mkOption types;
  in with types; {
    dm = mkOption {
      type = enum [ "sddm" "gdm" ];
      default = if cfg.wm == "gnome" then "gdm" else "sddm";
      defaultText = ''if config.desktop.wm == "gnome" then "gdm" else "sddm"'';
      description = ''
        The display manager to use.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.displayManager = {
      sddm = mkIf (cfg.dm == "sddm") {
        enable = true;
        theme = "catppuccin-sddm-corners";
        wayland.enable = true;

        settings = {
          General = { CursorTheme = "Vimix-Cursors"; };
          Theme = { EnableAvatars = true; };
        };
      };
    };
  };
}
