{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      duckdb
      glow # markdown previewer
      ouch # archive utility
    ];

    programs.yazi = {
      enable = true;
      enableFishIntegration = true;

      theme = {
        flavor = let theme = "dracula";
        in {
          dark = theme;
          light = theme;
        };
      };

      flavors = {
        dracula = pkgs.fetchFromGitHub {
          owner = "dracula";
          repo = "yazi";
          rev = "99b60fd76df4cce2778c7e6c611bfd733cf73866";
          hash = "sha256-dFhBT9s/54jDP6ZpRkakbS5khUesk0xEtv+xtPrqHVo=";
        };
      };

      plugins = {
        inherit (pkgs.yaziPlugins)
          chmod duckdb full-border git glow lazygit mediainfo mount ouch
          projects relative-motions restore rich-preview smart-filter
          smart-enter sudo yatline;

        # use from pkgs.yaziPlugins after update flake inputs
        smart-paste = pkgs.yaziPlugins.mkYaziPlugin {
          pname = "smart-paste.yazi";
          version = "0-unstable-2025-04-27";
          src = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "864a0210d9ba1e8eb925160c2e2a25342031d8d3";
            hash = "sha256-m3709h7/AHJAtoJ3ebDA40c77D+5dCycpecprjVqj/k=";
          };
        };
      };

      settings = {
        plugin = {
          prepend_fetchers = [
            {
              id = "git";
              name = "*";
              run = "git";
            }
            {
              id = "git";
              name = "*/";
              run = "git";
            }
          ];

          prepend_previewers = let
            ouch = map (type: {
              run = "ouch";
              mime = "application/${type}";
            }) [
              "*zip"
              "x-tar"
              "x-bzip2"
              "x-7z-compressed"
              "x-rar"
              "x-xz"
              "xz"
            ];

            duckdb = map (type: {
              run = "duckdb";
              name = "*.${type}";
            }) [ "csv" "tsv" "json" "parquet" "txt" "xlsx" "db" "duckdb" ];
          in [
            {
              name = "*.md";
              run = "glow";
            }
            # replace magick, image, video with mediainfo
            {
              mime = "{audio,video,image}/*";
              run = "mediainfo";
            }
            {
              mime = "application/subrip";
              run = "mediainfo";
            }
          ] ++ ouch ++ duckdb;

          prepend_preloaders = let
            duckdb = map (type: {
              run = "duckdb";
              name = "*.${type}";
              multi = false;
            }) [ "csv" "tsv" "json" "parquet" "txt" "xlsx" ];
          in [
            # replace magick, image, video with mediainfo
            {
              mime = "{audio,video,image}/*";
              run = "mediainfo";
            }
            {
              mime = "application/subrip";
              run = "mediainfo";
            }
          ] ++ duckdb;
        };
      };

      keymap = {
        manager = {
          prepend_keymap = [
            {
              on = [ "c" "z" ];
              run = "plugin ouch tar.xz";
              desc = "Compress with ouch";
            }
            {
              on = [ "c" "m" ];
              run = "plugin chmod";
              desc = "Change permissions";
            }
            {
              on = [ "d" "u" ];
              run = "plugin restore";
              desc = "Restore last deleted files/folders";
            }
            {
              on = [ "g" "i" ];
              run = "plugin lazygit";
              desc = "Run lazygit";
            }
            {
              on = "F";
              run = "plugin smart-filter";
              desc = "Smart filter";
            }
            {
              on = "l";
              run = "plugin smart-enter";
              desc = "Enter the child directory, or open the file";
            }
            {
              on = "p";
              run = "plugin smart-paste";
              desc = "Paste into the hovered directory or CWD";
            }

            # duckdb
            {
              on = "H";
              run = "plugin duckdb -1";
              desc = "Scroll one column to the left";
            }
            {
              on = "L";
              run = "plugin duckdb +1";
              desc = "Scroll one column to the right";
            }
            {
              on = [ "g" "o" ];
              run = "plugin duckdb -open";
              desc = "Open with duckdb";
            }
            {
              on = [ "g" "u" ];
              run = "plugin duckdb -ui";
              desc = "Open with duckdb ui";
            }
          ];
        };
      };

      initLua = let
        plugins = [ "duckdb" "git" "full-border" ];
        setupPlugins = lib.concatStringsSep "\n"
          (map (p: "require('${p}'):setup()") plugins);
      in ''
          ${setupPlugins}
          require("full-border"):setup {
            type = ui.Border.ROUNDED,
          }

          require("yatline"):setup({
          show_background = false,

          header_line = {
            left = {
              section_a = {
                {type = "line", custom = false, name = "tabs", params = {"left"}},
              },
              section_b = {},
              section_c = {}
            },
            right = {
              section_a = {
                {type = "string", custom = false, name = "date", params = {"%A, %d %B %Y"}},
              },
              section_b = {
                {type = "string", custom = false, name = "date", params = {"%X"}},
              },
              section_c = {}
            }
          },

          status_line = {
            left = {
              section_a = {
                {type = "string", custom = false, name = "tab_mode"},
              },
              section_b = {
                {type = "string", custom = false, name = "hovered_size"},
              },
              section_c = {
                {type = "string", custom = false, name = "hovered_path"},
                {type = "coloreds", custom = false, name = "count"},
              }
            },
            right = {
              section_a = {
                {type = "string", custom = false, name = "cursor_position"},
              },
              section_b = {
                {type = "string", custom = false, name = "cursor_percentage"},
              },
              section_c = {
                {type = "string", custom = false, name = "hovered_file_extension", params = {true}},
                {type = "coloreds", custom = false, name = "permissions"},
              }
            }
          },
        })
      '';
    };
  };
}
