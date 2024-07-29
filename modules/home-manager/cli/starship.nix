{ config, lib, ... }:

let
  inherit (lib) concatStrings;
  cfg = config.cli;
in {
  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;

      settings = {
        format = concatStrings [
          "[λ](bold red)"
          "$username$hostname "
          "[{](purple) $directory$git_branch$git_status$git_state [}](purple) "
          "$shell"
          "$container"
          "$docker_context"
          "$nodejs"
          "$deno"
          "$bun"
          "$python"
          "$rust"
          "$fill"
          "$shlvl"
          "$kubernetes"
          "$nix_shell"
          "$time"

          "$line_break"
          "$character"
        ];

        right_format = concatStrings [ "$cmd_duration" "$status" ];

        add_newline = false;

        palette = "dracula";

        palettes.dracula = {
          background = "#282a36";
          current = "#44475a";
          selection = "#44475a";
          foreground = "#f8f8f2";
          comment = "#6272a4";
          cyan = "#8be9fd";
          green = "#50fa7b";
          orange = "#ffb86c";
          pink = "#ff79c6";
          purple = "#bd93f9";
          red = "#ff5555";
          yellow = "#f1fa8c";
        };

        character = {
          success_symbol = "[󰄾](bold red)";
          error_symbol = "[󰄾](bold yellow)";
          vimcmd_symbol = "[󰄼](bold green)";
          vimcmd_replace_one_symbol = "[󰄼](bold purple)";
          vimcmd_replace_symbol = "[󰄼](bold purple)";
          vimcmd_visual_symbol = "[󰄼](bold yellow)";
        };

        bun.format = " [$symbol($version )]($style)";

        cmd_duration.show_milliseconds = true;

        directory = {
          format = "[$path]($style)[$read_only]($read_only_style)";
          read_only = " 󰌾";
        };

        docker_context.symbol = " ";

        fill.symbol = " ";

        git_branch = {
          format = " [$branch(:$remote_branch)]($style)";
          style = "green";
          symbol = " ";
        };

        git_state.format =
          "\\([$state( $progress_current/$progress_total)]($style)\\)";

        git_status = {
          format = " ([$ahead_behind$all_status]($style))";
          style = "yellow";
          modified = "!\${count}";
          ahead = "⇡\${count}";
          diverged = "⇕⇡\${ahead_count} ⇣\${behind_count}";
          behind = "⇣\${count}";
        };

        golang.symbol = " ";

        hostname = {
          format = "[$hostname\\)]($style)";
          style = "cyan";
          ssh_only = true;
          ssh_symbol = " ";
          disabled = false;
        };

        kubernetes = {
          format = "[$symbol$context/$namespace]($style) ";
          style = "pink";
          disabled = true;
          # figure out better way to do this
          detect_folders = [ "ci" ];
        };

        nix_shell = {
          symbol = " ";
          style = "purple";
          format = "[$symbol $state()](blue) ";
        };

        nodejs = {
          format = "[$symbol($version )]($style)";
          symbol = " ";
        };

        python = {
          format =
            "[\${symbol}\${pyenv_prefix}(\${version} )(\\($virtualenv\\) )]($style)";
          symbol = " ";
        };

        rust = {
          format = "[$symbol($version )]($style)";
          symbol = " ";
        };

        shell = {
          format = "[$indicator]($style)";
          style = "cyan bold";
          disabled = false;

          bash_indicator = "bash ";
          fish_indicator = "";
          zsh_indicator = "zsh ";
          powershell_indicator = "psh ";
          ion_indicator = "ion ";
          elvish_indicator = "esh ";
          tcsh_indicator = "tsh ";
          xonsh_indicator = "xsh ";
          cmd_indicator = "cmd ";
          nu_indicator = "nu ";
          unknown_indicator = "mystery shell ";
        };

        shlvl = {
          format = "[$shlvl levels down]($style) ";
          disabled = false;
          threshold = 3;
        };

        status = {
          format = "[$symbol$status]($style) ";
          disabled = false;
          symbol = "✘ ";
        };

        time = {
          format = "[\\[$time\\]]($style) ";
          style = "cyan";
          disabled = false;
        };

        username = {
          style_user = "cyan";
          style_root = "black bold";
          format = " [\\($user@]($style)";
          disabled = false;
        };
      };
    };
  };
}
