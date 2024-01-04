{ pkgs, lib, config, ... }:
let
  inherit (lib) mkIf;
  hasPackage = pname:
    lib.any (p: p ? pname && p.pname == pname) config.home.packages;
  hasRipgrep = hasPackage "ripgrep";
  hasExa = hasPackage "eza";
  hasNeovim = config.programs.neovim.enable;
  hasKitty = config.programs.kitty.enable;
in {
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

      # grep using ripgrep and pass to nvim
      nvimrg =
        mkIf (hasNeovim && hasRipgrep) "nvim -q (rg --vimgrep $argv | psub)";
    };

    plugins = [{
      name = "fisher";
      src = pkgs.fetchFromGitHub {
        owner = "jorgebucaran";
        repo = "fisher";
        rev = "2efd33ccd0777ece3f58895a093f32932bd377b6";
        sha256 = "sha256-e8gIaVbuUzTwKtuMPNXBT5STeddYqQegduWBtURLT3M=";
      };
    }];

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
    '';
  };
}
