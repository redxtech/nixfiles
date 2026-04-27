{
  den.aspects.multiplexer.homeManager =
    { pkgs, ... }:
    {
      programs.tmux = {
        enable = true;

        prefix = "C-a";
        baseIndex = 1;
        terminal = "tmux-256color";
        clock24 = true;
        mouse = true;

        plugins = with pkgs.tmuxPlugins; [
          sensible
          sessionist
          vim-tmux-navigator
          {
            plugin = dracula;
            extraConfig = ''
              set -g @dracula-refresh-rate 5
              set -g @dracula-show-flags true
              set -g @dracula-show-powerline true
              set -g @dracula-show-battery false
              set -g @dracula-show-left-icon session
              set -g @dracula-border-contrast true
              set -g @dracula-show-empty-plugins false

              set -g @dracula-military-time true
              set -g @dracula-show-timezone false

              set -g @dracula-show-fahrenheit false
              set -g @dracula-cpu-display-load false

              set -g @dracula-ram-usage-colors "green dark_gray"
              set -g @dracula-cpu-usage-colors "pink dark_gray"

              set -g @dracula-plugins "cpu-usage ram-usage time"
            '';
          }
          {
            plugin = resurrect;
            extraConfig = "set -g @resurrect-strategy-nvim 'session'";
          }
          {
            plugin = continuum;
            extraConfig = ''
              set -g @continuum-restore 'on'
              set -g @continuum-save-interval '60' # minutes
            '';
          }
        ];

        extraConfig = ''
          # set window split keybind
          bind - split-window -v -c '#{pane_current_path}'
          bind \\ split-window -h -c '#{pane_current_path}'

          # bind resizing panes
          bind -r C-Up resize-pane -U 2
          bind -r C-Down resize-pane -D 2
          bind -r C-Right resize-pane -R 2
          bind -r C-Left resize-pane -L 2

          bind -n S-Up resize-pane -U 5
          bind -n S-Down resize-pane -D 5
          bind -n S-Right resize-pane -R 10
          bind -n S-Left resize-pane -L 10

          # window binds
          bind c new-window
          bind b break-pane -d


          # sessions binds
          bind C-j split-window -v "tmux list-sessions | sed -E 's/:.*$//' | grep -v \"^\"(tmux display-message -p '#S')\"\" | fzf --reverse | xargs tmux switch-client -t"

          # bind re-sourcing
          bind r source-file $HOME/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"

          # quick keybinds
          bind h split-window -h "htop"
          bind t split-window -h "vim ~/.tmux.conf"
          bind v split-window -h "vim ~/.config/nvim/init.vim"

          # prompted join-pane
          bind j command-prompt -p "join pane from: "  "join-pane -h -s '%%'"

          # easily swap a pane (targeted by pane number) with the current pane
          bind s display-panes\; command-prompt -p "pane #: "  "swap-pane -t '%%'"

          bind C-b send-keys 'tat && exit' 'C-m'
          bind K run-shell 'tmux switch-client -n \; kill-session -t "$(tmux display-message -p "#S")" || tmux kill-session'

          # some options
          set -ga terminal-overrides ",xterm-kitty:RGB"
          set -g renumber-windows on
          set -g mode-style "fg=black,bg=brightgreen"
          set -g set-titles on
          set -g set-titles-string "#T"
          set -g display-time 2500
          set -g status-interval 3

          set -g pane-active-border-style bg=default,fg=red
          set -g pane-border-style fg=white

        '';
      };

      programs.zellij = {
        enable = true;
        enableFishIntegration = false;

        settings = {
          pane_frames = false;
          default_mode = "locked";
          session_serialization = false;
          show_startup_tips = false;

          keybinds = {
            _props.clear-defaults = true;
            # doesn't matter what this is,
            # we just need some key so that config validation passes
            normal.bind = {
              _args = [ "left" ];
              MoveFocus = [ "left" ];
            };
          };
        };
      };

      xdg.configFile."zellij/layouts/neovim.kdl".text = ''
        layout { 
          pane {
            command "nvim"
            close_on_exit true
          }
        }'';
    };
}
