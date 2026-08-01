{
  flake.homeManagerModules.kimaki =
    {
      self',
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.kimaki;
    in
    {
      options.services.kimaki = {
        enable = lib.mkEnableOption "Kimaki Discord agent orchestrator";

        package = lib.mkOption {
          type = lib.types.package;
          default = self'.packages.kimaki;
          defaultText = lib.literalExpression "inputs.nixfiles.packages.\${pkgs.stdenv.hostPlatform.system}.kimaki";
          description = "The Kimaki package to use.";
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Additional packages available to Kimaki agents.";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "--no-auto-upgrade" ];
          example = [
            "--no-auto-upgrade"
            "--use-worktrees"
          ];
          description = "Additional command-line arguments passed to Kimaki.";
        };

        user = lib.mkOption {
          type = lib.types.str;
          default = "gabe";
          example = "you";
          description = "User to run Kimaki as.";
        };

        databasePath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "%h/.kimaki/discord-sessions.db";
          description = "Database path that must exist before starting Kimaki, or null to disable the check.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        systemd.user.services.kimaki = {
          Unit = {
            Description = "Kimaki Discord agent orchestrator";
            ConditionUser = cfg.user;
          }
          // lib.optionalAttrs (cfg.databasePath != null) {
            ConditionPathExists = cfg.databasePath;
          };

          Service = {
            ExecStart = lib.escapeShellArgs ([ (lib.getExe cfg.package) ] ++ cfg.extraArgs);
            Environment = lib.optional (cfg.extraPackages != [ ]) "PATH=${lib.makeBinPath cfg.extraPackages}";
            Restart = "on-failure";
            RestartSec = 10;
            WorkingDirectory = "%h";
          };

          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
