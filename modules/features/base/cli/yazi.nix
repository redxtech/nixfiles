{
  den.aspects.yazi.homeManager =
    { pkgs, lib, ... }:
    {
      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
        shellWrapperName = "y";

        plugins = {
          inherit (pkgs.yaziPlugins)
            chmod
            duckdb
            full-border
            git
            glow
            lazygit
            mediainfo
            mount
            ouch
            projects
            relative-motions
            restore
            rich-preview
            smart-filter
            smart-enter
            sudo
            yatline
            ;

          # use from pkgs.yaziPlugins after update flake inputs
          smart-paste = pkgs.yaziPlugins.mkYaziPlugin {
            pname = "smart-paste.yazi";
            version = "0-unstable-2025-04-27";
            src = pkgs.fetchFromGitHub {
              owner = "yazi-rs";
              repo = "plugins";
              rev = "ac82af3e10f9a32cecd9f87ac64b3f9de7c7aea7";
              hash = "sha256-svc7I2E+tVMEUWUvIS6i3oTGfLq13eaI61T0c1MQ8qQ=";
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

            prepend_previewers =
              let
                ouch =
                  map
                    (type: {
                      run = "ouch";
                      mime = "application/${type}";
                    })
                    [
                      "*zip"
                      "x-tar"
                      "x-bzip2"
                      "x-7z-compressed"
                      "x-rar"
                      "x-xz"
                      "xz"
                    ];

                duckdb =
                  map
                    (type: {
                      run = "duckdb";
                      name = "*.${type}";
                    })
                    [
                      "csv"
                      "tsv"
                      "json"
                      "parquet"
                      "txt"
                      "xlsx"
                      "db"
                      "duckdb"
                    ];
              in
              [
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
              ]
              ++ ouch
              ++ duckdb;

            prepend_preloaders =
              let
                duckdb =
                  map
                    (type: {
                      run = "duckdb";
                      name = "*.${type}";
                      multi = false;
                    })
                    [
                      "csv"
                      "tsv"
                      "json"
                      "parquet"
                      "txt"
                      "xlsx"
                    ];
              in
              [
                # replace magick, image, video with mediainfo
                {
                  mime = "{audio,video,image}/*";
                  run = "mediainfo";
                }
                {
                  mime = "application/subrip";
                  run = "mediainfo";
                }
              ]
              ++ duckdb;
          };
        };

        keymap = {
          manager = {
            prepend_keymap = [
              {
                on = [
                  "c"
                  "z"
                ];
                run = "plugin ouch tar.xz";
                desc = "Compress with ouch";
              }
              {
                on = [
                  "c"
                  "m"
                ];
                run = "plugin chmod";
                desc = "Change permissions";
              }
              {
                on = [
                  "d"
                  "u"
                ];
                run = "plugin restore";
                desc = "Restore last deleted files/folders";
              }
              {
                on = [
                  "g"
                  "i"
                ];
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
                on = [
                  "g"
                  "o"
                ];
                run = "plugin duckdb -open";
                desc = "Open with duckdb";
              }
              {
                on = [
                  "g"
                  "u"
                ];
                run = "plugin duckdb -ui";
                desc = "Open with duckdb ui";
              }
            ];
          };
        };

        initLua =
          let
            plugins = [
              "duckdb"
              "git"
              "full-border"
            ];
            setupPlugins = lib.concatStringsSep "\n" (map (p: "require('${p}'):setup()") plugins);
          in
          ''
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

        # TODO: add vfs settings for sshfs
        # vfs = { };
      };
    };
}
