{ config, lib, pkgs, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        import = [ "${pkgs.alacritty-theme}/dracula.toml" ];

        window = {
          dimensions = {
            columns = 140;
            lines = 35;
          };

          padding = {
            x = 0;
            y = 0;
          };
          dynamic_padding = false;

          opacity = 0.9;
          dynamic_title = true;
          decorations = "full";
          startup_mode = "Windowed";
        };

        scrolling = {
          history = 100000;
          multiplier = 3;
        };

        font = {
          normal.family = "Dank Mono";
          size = 11.0;

          offset = {
            x = 0;
            y = 0;
          };

          glyph_offset = {
            x = 0;
            y = 0;
          };
        };

        bell = {
          animation = "EaseOutExpo";
          duration = 1;
          color = "#000000";
        };

        mouse = {
          hide_when_typing = false;

          bindings = [{
            mouse = "Middle";
            action = "PasteSelection";
          }];
        };

        selection = {
          semantic_escape_chars = '',│`|:"' ()[]{}<>'';
          save_to_clipboard = false;
        };

        cursor = {
          style = "Beam";
          unfocused_hollow = true;
        };

        live_config_reload = true;

        keyboard.bindings = [
          {
            key = "N";
            mods = "Control|Shift";
            action = "SpawnNewInstance";
          }
          {
            key = "T";
            mods = "Control|Shift";
            action = "SpawnNewInstance";
          }
        ];
      };
    };
  };
}

