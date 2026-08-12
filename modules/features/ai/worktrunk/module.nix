{
  flake.homeManagerModules.worktrunk =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.programs.worktrunk;
    in
    {
      options.programs.worktrunk = {
        enable = lib.mkEnableOption "Worktrunk";

        package = lib.mkPackageOption pkgs "worktrunk" { };

        enableBashIntegration = lib.mkEnableOption "Bash integration" // {
          default = config.programs.bash.enable;
          defaultText = lib.literalExpression "config.programs.bash.enable";
        };

        enableZshIntegration = lib.mkEnableOption "Zsh integration" // {
          default = config.programs.zsh.enable;
          defaultText = lib.literalExpression "config.programs.zsh.enable";
        };

        enableFishIntegration = lib.mkEnableOption "Fish integration" // {
          default = config.programs.fish.enable;
          defaultText = lib.literalExpression "config.programs.fish.enable";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            home.packages = [ cfg.package ];
          }

          (lib.mkIf cfg.enableBashIntegration {
            programs.bash.initExtra = ''
              eval "$(${lib.getExe cfg.package} config shell init bash)"
            '';
          })

          (lib.mkIf cfg.enableZshIntegration {
            programs.zsh.initContent = ''
              eval "$(${lib.getExe cfg.package} config shell init zsh)"
            '';
          })

          (lib.mkIf cfg.enableFishIntegration {
            programs.fish.functions.wt = ''
              # Completion mode: let the binary emit completions directly. A stale
              # third-party completion may invoke the bare `wt` command with COMPLETE
              # set; without this guard that lands back on this stub and recurses.
              if set -q COMPLETE
                  command wt $argv
                  return
              end
              ${lib.getExe cfg.package} config shell init fish | source
              # If source fails, the function is not replaced and calling it again recurses.
              set -l wt_status $pipestatus[1]
              set -l source_status $pipestatus[2]
              test $wt_status -eq 0; or return $wt_status
              test $source_status -eq 0; or return $source_status
              wt $argv
            '';

            xdg.configFile."fish/completions/wt.fish".text = ''
              # worktrunk completions for fish
              complete --keep-order --exclusive --command wt --arguments "(test -n \"\$WORKTRUNK_BIN\"; or set -l WORKTRUNK_BIN (type -P wt 2>/dev/null); and COMPLETE=fish \$WORKTRUNK_BIN -- (commandline --current-process --tokenize --cut-at-cursor) (commandline --current-token))"
            '';
          })
        ]
      );
    };
}
