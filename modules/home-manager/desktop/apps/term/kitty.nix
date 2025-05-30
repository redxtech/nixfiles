{ config, lib, pkgs, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    home.sessionVariables.TERMINAL = "kitty";

    programs.kitty = {
      enable = true;

      themeFile = "Dracula";
      font = {
        name = config.fontProfiles.monospace.family;
        size = 13;
      };

      # keybindings = {};

      settings = {
        cursor_shape = "beam";

        scrollback_lines = 10000;
        # scrollback_pager =
        #   "${config.xdg.configHome}/kitty/pager.sh 'INPUT_LINE_NUMBER' 'CURSOR_LINE' 'CURSOR_COLUMN'";
        scrollback_pager_history_size = 100;

        url_color = "#0087bd";
        url_style = "single";

        repaint_delay = 7;

        enable_audio_bell = false;

        remember_window_size = false;
        initial_window_width = "115c";
        initial_window_height = "30c";

        tab_bar_edge = "bottom";
        tab_bar_style = "powerline";
        tab_bar_min_tabs = 2;
        tab_activity_symbol = "*";
        tab_title_template = "{index}  {title}";

        active_tab_foreground = "${config.user-theme.fg}";
        active_tab_background = "${config.user-theme.bg}";
        active_tab_font_style = "bold-italic";
        inactive_tab_foreground = "${config.user-theme.fg}";
        inactive_tab_background = "${config.user-theme.bg}";
        inactive_tab_font_style = "normal";

        background_opacity = "0.9";

        editor = "tu";

        allow_remote_control = "socket-only";
        listen_on = "unix:/tmp/kitty";
        shell_integration = "enabled";

        wayland_titlebar_color = "background";
      };

      extraConfig = ''
        # Nerd Fonts v3.2.0
        symbol_map U+e000-U+e00a,U+ea60-U+ebeb,U+e0a0-U+e0c8,U+e0ca,U+e0cc-U+e0d7,U+e200-U+e2a9,U+e300-U+e3e3,U+e5fa-U+e6b1,U+e700-U+e7c5,U+ed00-U+efc1,U+f000-U+f2ff,U+f000-U+f2e0,U+f300-U+f372,U+f400-U+f533,U+f0001-U+f1af0 Symbols Nerd Font Mono

        modify_font strikethrough_position    130%
        modify_font strikethrough_thickness   0.1px
        modify_font underline_position        150%
        modify_font underline_thickness       0.1px
        # modify_font cell_height               125%

        # kitty-scrollback.nvim: kitten alias
        action_alias kitty_scrollback_nvim kitten /home/gabe/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py
        map kitty_mod+h kitty_scrollback_nvim                                                                                                                 # browse scrollback buffer in nvim
        map kitty_mod+g kitty_scrollback_nvim --config ksb_builtin_last_cmd_output                                                                            # browse output of the last shell command in nvim
        mouse_map ctrl+shift+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output # show clicked command output in nvim
      '';

      shellIntegration.enableZshIntegration = true;
      shellIntegration.enableFishIntegration = true;
      shellIntegration.mode = "enabled";
    };

    xdg.configFile."kitty/pager.sh".text = ''
      #!${pkgs.bash}/bin/bash
      set -eu

      if [ "$#" -eq 3 ]; then
        INPUT_LINE_NUMBER=''${1:-0}
        CURSOR_LINE=''${2:-1}
        CURSOR_COLUMN=''${3:-1}
        AUTOCMD_TERMCLOSE_CMD="call cursor(max([0,''${INPUT_LINE_NUMBER}-1])+''${CURSOR_LINE}, ''${CURSOR_COLUMN})"
      else
        AUTOCMD_TERMCLOSE_CMD="normal G"
      fi

      exec tu 63<&0 0</dev/null \
        -u NONE \
        -c "map <silent> q :qa!<CR>" \
        -c "set shell=bash scrollback=100000 termguicolors laststatus=0 clipboard+=unnamedplus" \
        -c "autocmd TermEnter * stopinsert" \
        -c "autocmd TermClose * ''${AUTOCMD_TERMCLOSE_CMD}" \
        -c 'terminal sed </dev/fd/63 -e "s/'$'\x1b''']8;;file:[^\]*[\]//g" && sleep 0.01 && printf "'$'\x1b''']2;"'
    '';
  };
}
