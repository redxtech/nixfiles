{ self, ... }:

{
  flake.homeManagerModules.openportal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.openportal;
      arguments = [
        (lib.getExe cfg.package)
        "--directory"
        cfg.directory
        "--port"
        (toString cfg.port)
        "--opencode-port"
        (toString cfg.opencodePort)
        "--hostname"
        cfg.hostname
      ]
      ++ lib.optionals (cfg.name != null) [
        "--name"
        cfg.name
      ]
      ++ cfg.extraArgs;
    in
    {
      options.services.openportal = {
        enable = lib.mkEnableOption "OpenPortal web interface for OpenCode";

        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.openportal;
          defaultText = lib.literalExpression "inputs.nixfiles.packages.\${pkgs.stdenv.hostPlatform.system}.openportal";
          description = "The OpenPortal package to use.";
        };

        directory = lib.mkOption {
          type = lib.types.str;
          default = "%h";
          description = "Working directory exposed through OpenPortal.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 3000;
          description = "Port for the OpenPortal web interface.";
        };

        opencodePort = lib.mkOption {
          type = lib.types.port;
          default = 4000;
          description = "Port for the OpenCode server managed by OpenPortal.";
        };

        hostname = lib.mkOption {
          type = lib.types.str;
          default = "0.0.0.0";
          description = "Address on which OpenPortal listens.";
        };

        name = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "OpenPortal instance name, or null to derive it from the directory.";
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Additional packages available to OpenPortal.";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional command-line arguments passed to OpenPortal.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        systemd.user.services.openportal = {
          Unit = {
            Description = "OpenPortal web interface for OpenCode";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            ExecStart = lib.escapeShellArgs arguments;
            Environment = lib.optional (cfg.extraPackages != [ ]) "PATH=${lib.makeBinPath cfg.extraPackages}";
            Restart = "on-failure";
            RestartSec = 10;
            WorkingDirectory = cfg.directory;
          };

          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
