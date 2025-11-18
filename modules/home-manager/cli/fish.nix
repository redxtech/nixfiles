{ config, lib, pkgs, hostnames, ... }:

let
  inherit (lib) mkIf concatStringsSep;
  cfg = config.cli;

  language = name: text: text;
  hasPackage = pname:
    lib.any (p: p ? pname && p.pname == pname) config.home.packages;

  hasRipgrep = hasPackage "ripgrep";
  hasNeovim = config.programs.neovim.enable;
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs; [ babelfish grc ];

    programs.fish = {
      enable = true;

      shellAbbrs = {
        # nix
        nd = "nix develop";
        ndi = "nix develop --impure";
        nr = "nix run nixpkgs#";
        nsn = "nix shell nixpkgs#";
        nbn = "nix build nixpkgs#";
        nbp =
          "nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'";
        nrr = "nixos-rebuild-remote";

        # xmodmap
        XMO = "xmodmap ~/.Xmodmap";

        # typos
        clera = "clear";
        claer = "clear";
        dc = "cd";
        ecoh = "echo";
        yamd = "yadm";
        yand = "yadm";
        pacuar = "pacaur";
        sudp = "sudo";
        yarm = "yarn";
      };

      functions = {
        # disable greeting
        fish_greeting = "";

        fish_user_key_bindings = language "fish" ''
          # fish_vi_key_bindings

          # use search with tab complete - next best thing to fzf tab completion
          bind --mode insert \t complete-and-search
          bind --mode insert --key btab complete
          bind --mode visual \t complete-and-search
          bind --mode visual --key btab complete
          bind \t complete-and-search
          bind --key btab complete

          # open command buffer in vim when alt+e is pressed
          bind \ee edit_command_buffer
        '';

        # list all paths in $PATH
        paths = language "fish" ''
          for path in $PATH
            echo -- $path
          end
        '';

        # make a directory and cd into it
        mkcd = language "fish" ''
          mkdir -pv $argv
          cd $argv
        '';

        # renames the current working directory
        mvcd = language "fish" ''
          set cwd $PWD
          set newcwd $argv[1]
          cd ..
          mv $cwd $newcwd
          cd $newcwd
          pwd
        '';

        tat = {
          description = "Open or attach to a tmux session";
          argumentNames = [ "session" ];
          body = ''
            if test "$session" = "ls";
            	tmux ls
            	return
            end

            # if no argument is passed, use $USER
            if test -z "$session"
            	set session "$USER"
            end

            tmux new -A -s "$session"
          '';
        };

        # quick wrapper to make running `nix develop` without any arguments
        # run Fish instead of Bash.
        nix = {
          wraps = "nix";
          description = "Wraps `nix develop` to run fish instead of bash";
          body = language "fish" ''
            if status is-interactive and test (count $argv) = 1 -a "$argv[1]" = develop
              # Special case: if there's an initialized .flake directory, use that.
              if test -d .flake -a -f .flake/flake.nix
                announce nix develop $PWD/.flake --command (status fish-path)
              else
                announce nix develop --command (status fish-path)
              end

            else
              command nix $argv
            end
          '';
        };

        nd = {
          wraps = "nix develop";
          description = "Wraps `nix develop` to run fish instead of bash";
          body = language "fish" ''
            if status is-interactive
              nix develop $argv -c $SHELL
            end
          '';
        };

        nixos-rebuild-remote = {
          description = "Rebuilds a remote NixOS machine";
          wraps = "nixos-rebuild switch";
          body = ''
            nixos-rebuild --flake "$FLAKE#$argv[1]" \
              --fast \
              --target-host "root@$argv[1]" \
              --build-host "root@$argv[1]" \
              switch
          '';
        };

        cdeploy = {
          description = "Remotely deploys a NixOS machine with cachix-deploy";
          body = ''
            set spec $(nix build "$FLAKE#deploy-$argv[1]" --print-out-paths)
            cachix push gabedunn $spec
            cachix deploy activate $spec
          '';
        };

        rdeploy = {
          description = "Remotely deploys a NixOS machine with deploy-rs";
          wraps = "deploy";
          body = ''
            deploy --targets "$FLAKE#$argv[1]"
          '';
        };

        hclients = {
          description = "List important information about hyprctl clients";
          body = ''
            hyprctl clients -j | jq '.[] | {class,title,initialClass,initialTitle,workspace}'
          '';
        };

        __fish_nixos_remote_complete = {
          body = ''
            set -l hostnames ${concatStringsSep " " hostnames}
            for host in $hostnames
              echo $host
            end
          '';
        };

        # grep using ripgrep and pass to nvim
        nvimrg =
          mkIf (hasNeovim && hasRipgrep) "nvim -q (rg --vimgrep $argv | psub)";

        # prints the command to the screen, colorized it would be when executed
        # at the command line, then executes the command.
        # this is meant to look like the user is executing the command, while
        # also making it clear it's happening automatically. Useful for functions
        # where it's just some simple commands being run in sequence.
        announce = language "fish" ''
          set colored_command (echo -- "$argv" | fish_indent --ansi)
          echo "$(set_color magenta)~~>$(set_color normal) $colored_command"
          $argv
        '';

        # why's it called 'o'? because it's really good ;)
        # i'm joking, it's just because it's on my home row (colemak layout)
        o = {
          wraps = "cd";
          description = "Interactive cd that offers to create directories";
          body = language "fish" ''
            # Some git trickery first. If the function is called with no arguments,
            # typically that means to cd to $HOME, but we can be smarter - if you're
            # in a git repo and not in its root, cd to the root.
            if test (count $argv) -eq 0
              set git_root (git rev-parse --git-dir 2>/dev/null | path dirname)
              if test $status -eq 0 -a "$git_root" != .
                cd $git_root
                return 0
              end
            end

            # Now that's out of the way
            cd $argv
            set cd_status $status
            if test $cd_status -ne 0
              and gum confirm "Create the directory? ($argv[-1])"
              echo "Creating directory"
              command mkdir -p -- $argv[-1]
              builtin cd $argv[-1]
              return 0
            else
              return $cd_status
            end
          '';
        };

        # cd to a temporary directory
        tcd = language "fish" ''
          cd (mktemp -d)
        '';
      };

      plugins = with pkgs;
        with fishPlugins; [
          {
            name = "fisher";
            src = fetchFromGitHub {
              owner = "jorgebucaran";
              repo = "fisher";
              rev = "1f0dc2b4970da160605638cb0f157079660d6e04";
              hash = "sha256-pR5RKU+zIb7CS0Y6vjx2QIZ8Iu/3ojRfAcAdjCOxl1U=";
            };
          }
          {
            name = "autopair";
            src = autopair.src;
          }
          {
            name = "bass";
            src = bass.src;
          }
          {
            name = "coloured-man-pages";
            src = colored-man-pages.src;
          }
          {
            name = "done";
            src = done.src;
          }
          {
            name = "forgit";
            src = forgit.src;
          }
          {
            name = "fzf-fish";
            src = fzf-fish.src;
          }
          {
            name = "grc";
            src = grc.src;
          }
          {
            name = "humantime";
            src = humantime-fish.src;
          }
          {
            name = "puffer";
            src = puffer.src;
          }
          {
            name = "sponge";
            src = sponge.src;
          }
          {
            name = "fish-not-vim";
            src = fetchFromGitHub {
              owner = "redxtech";
              repo = "fish-not-vim";
              rev = "1a506e9a436ec58c9e7eee9e24d2b02d0a90677f";
              hash = "sha256-HnvsGSgfooelWzmUC8xVTSGYkwd07br8ewcCSfkIanQ=";
            };
          }
          {
            name = "fyshtemd";
            src = fetchFromGitHub {
              owner = "redxtech";
              repo = "fyshtemd";
              rev = "54898ce07333d1a7a0cd8821793a1a86cffca902";
              hash = "sha256-P/zC/6l3DPHLJErsi4/3ExTSoSo+Xj+ZhUmjsaUoKjc=";
            };
          }
          {
            name = "tacklebox";
            src = fetchFromGitHub {
              owner = "redxtech";
              repo = "tacklebox";
              rev = "d7fbff2fa196b194485f87a6060e1c6de9a03c8e";
              hash = "sha256-2FmCkbYUEWMv0lUk6TpWktXkRbYSDCcogcBMDdUhIFM=";
            };
          }
          {
            name = "unix-simple";
            src = fetchFromGitHub {
              owner = "redxtech";
              repo = "fish-unix-simple";
              rev = "04906ee89f3cb5f912789d051302f13a53869be1";
              hash = "sha256-TwgqpnwJO6dSyPcRf8xbM+o0YGjg8NVOUcED5+tSNHs=";
            };
          }
          {
            name = "fish-abbreviation-tips";
            src = fetchFromGitHub {
              owner = "gazorby";
              repo = "fish-abbreviation-tips";
              rev = "8ed76a62bb044ba4ad8e3e6832640178880df485";
              hash = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
            };
          }
          {
            name = "projectdo";
            src = fetchFromGitHub {
              owner = "paldepind";
              repo = "projectdo";
              rev = "c23dd73d9eed4632baf8551c9ee6c272c45144d3";
              hash = "sha256-j8wR+s1cMVMcNYXcVxmSf14UuHsRNq112jrMmevN9Dg=";
            };
          }
          {
            name = "nix.fish";
            src = fetchFromGitHub {
              owner = "kidonng";
              repo = "nix.fish";
              rev = "ad57d970841ae4a24521b5b1a68121cf385ba71e";
              hash = "sha256-GMV0GyORJ8Tt2S9wTCo2lkkLtetYv0rc19aA5KJbo48=";
            };
          }
          {
            name = "archlinux";
            src = fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-archlinux";
              rev = "1fd975f852bc2bd398e3cfd19780650b23233c27";
              hash = "sha256-Q77U18KYS/4BY0MUaFh7U/EA3AyidpurdTyR6C86KqI=";
            };
          }
          {
            name = "bak";
            src = fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-bak";
              rev = "93ce665e1e0ae405a4bbee102f782646e03cdfb6";
              hash = "sha256-5BeSsy2JFkaKfXOtscJZVoaSK4FO8H6MXuV43uKd4TI=";
            };
          }
          {
            name = "insist";
            src = fetchFromGitLab {
              owner = "lusiadas";
              repo = "insist";
              rev = "63ba665443b414b927d4628621668881bbed56af";
              hash = "sha256-J+pRBHOkWusAkFQ5oGMILpgSQmTNCSN22UfUTs3qnpg=";
            };
          }
        ];

      interactiveShellInit = ''
        # theme
        fish_config theme choose "Dracula"

        # kitty integration
        set --global KITTY_INSTALLATION_DIR "${pkgs.kitty}/lib/kitty"

        # use vim cursors
        set fish_cursor_default     block      blink
        set fish_cursor_insert      line       blink
        set fish_cursor_replace_one underscore blink
        set fish_cursor_visual      block

        # fzf config
        set fzf_diff_highlighter delta --paging=never --width=20
        fzf_configure_bindings --directory=\co

        # sponge clears typos from history when shell exits
        set sponge_purge_only_on_exit true

        # done config
        set __done_min_cmd_duration 10000 # 10 seconds

        # use fish for nix shells
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish | source

        # add completion for nixos-rebuild-remote
        complete -c nixos-rebuild-remote -a '(__fish_nixos_remote_complete)' -f
        complete -c cdeploy -a '(__fish_nixos_remote_complete)' -f
        complete -c rdeploy -a '(__fish_nixos_remote_complete)' -f

        # add completion for home assistant cli
        eval (_HASS_CLI_COMPLETE=fish_source ${pkgs.home-assistant-cli}/bin/hass-cli)
      '';

      shellInit = language "fish" ''
        # source local env variables
        if test -f ${config.xdg.configHome}/fish/env.local.fish;
          source ${config.xdg.configHome}/fish/env.local.fish
        end

        if test -f ${config.xdg.configHome}/fish/env.secrets.fish;
          source ${config.xdg.configHome}/fish/env.secrets.fish
        end

        if test -f ${config.sops.secrets."adguardian.fish".path};
          source ${config.sops.secrets."adguardian.fish".path}
        end
      '';
    };

    # file writing
    xdg.configFile."fish/env.secrets.fish".text = let
      inherit (builtins) concatStringsSep elemAt map;
      mkSecret = entry:
        let
          name = elemAt entry 0;
          secret = elemAt entry 1;
          cat = pkgs.coreutils + "/bin/cat";
          path = config.sops.secrets.${secret}.path;
        in ''set --export ${name} "$(${cat} ${path} 2>/dev/null)"'';
      secrets = [
        [ "YOUTUBE_API_KEY" "youtube" ]
        [ "BW_SESSION" "bw" ]
        [ "CACHIX_AUTH_TOKEN" "cachix" ]
        [ "CACHIX_ACTIVATE_TOKEN" "cachix-activate" ]
        [ "HASS_SERVER" "hass_url" ]
        [ "HASS_TOKEN" "hass_token" ]
        [ "OPENROUTER_KEY" "openrouter_key" ]
        [ "OPENAI_KEY" "openai_key" ]
      ];
      envFile = concatStringsSep "\n" (map mkSecret secrets);
    in envFile;
  };
}
