{ self, inputs, ... }:

{
  imports = [ inputs.devenv.flakeModule ];

  perSystem = { config, self', inputs', pkgs, system, ... }:
    let inherit (pkgs) lib;
    in {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          age
          fh
          git
          gnupg
          home-manager
          neovim
          nh
          nix
          sops
          ssh-to-age
          yadm
          inputs'.deploy-rs.packages.deploy-rs
        ];

        env.NIX_CONFIG =
          "extra-experimental-features = nix-command flakes repl-flake";

        shellHook = ''
          alias nrs="nh os switch"
        '';
      };

      devenv.shells.remote = {
        name = "remote";

        packages = with pkgs; [
          bat
          btop
          dua
          eza
          fd
          fish
          fzf
          git
          neovim
          nh
          nix
          ripgrep
          sops
          starship
          ssh-to-age
          tealdeer
        ];

        scripts = let x = exec: { inherit exec; };
        in builtins.mapAttrs (name: cmd: { exec = cmd; }) rec {
          ls = "eza --group-directories-first";
          la = "ls -al";
          l = "ls -l";
          tu = "nix run github:redxtech/tu";
        };

        env.NIX_CONFIG =
          "extra-experimental-features = nix-command flakes repl-flake";

        enterShell = ''
          alias ls="eza --group-directories-first"
          alias la="ls -la"
          alias l="ls -l"
          alias nrs="nh os switch"
        '';

        starship = {
          enable = true;
          config = {
            enable = true;
            path = let
              toTOML = pkgs.formats.toml { };
              starshipConfig = toTOML.generate "starship.toml" {

                format = lib.concatStrings [
                  "[λ](bold red)"
                  "$username$hostname "
                  "[{](purple) $directory$git_branch$git_status$git_state [}](purple) "
                  "$shell"
                  "$container"
                  "$fill"
                  "$shlvl"
                  "$nix_shell"
                  "#remote " # remote
                  "$time"

                  "$line_break"
                  "$character"
                ];

                right_format = lib.concatStrings [ "$cmd_duration" "$status" ];

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

                cmd_duration.show_milliseconds = true;

                directory = {
                  format = "[$path]($style)[$read_only]($read_only_style)";
                  read_only = " 󰌾";
                };

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

                hostname = {
                  format = "[$hostname\\)]($style)";
                  style = "cyan";
                  ssh_only = true;
                  ssh_symbol = " ";
                  disabled = false;
                };

                nix_shell = {
                  symbol = " ";
                  style = "purple";
                  format = "[$symbol $state()](blue) ";
                };

                shell = {
                  format = "[remote#$indicator]($style)";
                  style = "cyan bold";
                  disabled = false;

                  bash_indicator = "bash ";
                  fish_indicator = "fish";
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
            in starshipConfig;
          };
        };
      };
    };
}
