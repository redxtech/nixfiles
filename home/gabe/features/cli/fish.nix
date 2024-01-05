{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf;
  language = name: text: text;
  hasPackage = pname:
    lib.any (p: p ? pname && p.pname == pname) config.home.packages;
  hasRipgrep = hasPackage "ripgrep";
  hasExa = hasPackage "eza";
  hasNeovim = config.programs.neovim.enable;
  hasKitty = config.programs.kitty.enable;
in {
  home.packages = with pkgs; [ grc ];

  programs.fish = {
    enable = true;

    shellAbbrs = rec {
      # nix
      nsn = "nix shell nixpkgs#";
      nbn = "nix build nixpkgs#";

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

    # shellAliases = rec {
    #   # Clear screen and scrollback
    #   clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    # };

    functions = {
      # disable greeting
      fish_greeting = "";

      # list all paths in $PATH
      paths = language "fish" ''
        for path in $PATH
          echo -- $path
        end
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

      # quick wrapper to make running `nix develop` without any arguments
      # run Fish instead of Bash.
      nix = {
        wraps = "nix";
        description = "Wraps `nix develop` to run fish instead of bash";
        body = language "fish" ''
          if status is-interactive
            and test (count $argv) = 1 -a "$argv[1]" = develop

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
            rev = "2efd33ccd0777ece3f58895a093f32932bd377b6";
            sha256 = "sha256-e8gIaVbuUzTwKtuMPNXBT5STeddYqQegduWBtURLT3M=";
          };
        }
        {
          name = "autopair";
          src = autopair.src;
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
          name = "fish-abbreviation-tips";
          src = fetchFromGitHub {
            owner = "gazorby";
            repo = "fish-abbreviation-tips";
            rev = "8ed76a62bb044ba4ad8e3e6832640178880df485";
            sha256 = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
          };
        }
        {
          name = "projectdo";
          src = fetchFromGitHub {
            owner = "paldepind";
            repo = "projectdo";
            rev = "918ee7a95ca795097fe887d3b6ffe844b8b13ca5";
            sha256 = "sha256-C458NdUwND2ahoXW4kT4B/Mu3FdEHsjifE/SyWDWdiE=";
          };
        }
        {
          name = "bak";
          src = fetchFromGitHub {
            owner = "oh-my-fish";
            repo = "plugin-bak";
            rev = "93ce665e1e0ae405a4bbee102f782646e03cdfb6";
            sha256 = "sha256-5BeSsy2JFkaKfXOtscJZVoaSK4FO8H6MXuV43uKd4TI=";
          };
        }
        {
          name = "wttr";
          src = fetchFromGitHub {
            owner = "oh-my-fish";
            repo = "plugin-wttr";
            rev = "7500e382e6b29a463edc57598217ce0cfaf8c90c";
            sha256 = "sha256-k3FrRPxKCiObO6HgtDx8ORbcLmfSYQsQeq5SAoNfZbE=";
          };
        }
        {
          name = "insist";
          src = fetchFromGitLab {
            owner = "lusiadas";
            repo = "insist";
            rev = "63ba665443b414b927d4628621668881bbed56af";
            sha256 = "sha256-J+pRBHOkWusAkFQ5oGMILpgSQmTNCSN22UfUTs3qnpg=";
          };
        }
      ];

    interactiveShellInit = ''
      # theme
      fish_config theme choose "Dracula Official"

      # Open command buffer in vim when alt+e is pressed
      bind \ee edit_command_buffer

      # kitty integration
      set --global KITTY_INSTALLATION_DIR "${pkgs.kitty}/lib/kitty"
      set --global KITTY_SHELL_INTEGRATION enabled
      source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
      set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"

      # Use vim bindings and cursors
      fish_vi_key_bindings
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
      # set --append __done_exclude '^n?vim ^btop ^docker ^hx ^kitty ^micro ^ranger ^spt ^ssh ^yadm ^zsh'
    '';
  };
}
