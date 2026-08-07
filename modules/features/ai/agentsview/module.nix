{ inputs, ... }:

{
  flake.homeManagerModules.agentsview =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.agentsview;
      arguments = [
        (lib.getExe cfg.package)
        "serve"
        "--host"
        cfg.host
        "--port"
        (toString cfg.port)
        "--no-browser"
      ]
      ++ lib.optionals (cfg.publicUrl != null) [
        "--public-url"
        cfg.publicUrl
      ]
      ++ cfg.extraArgs;
    in
    {
      options.services.agentsview = {
        enable = lib.mkEnableOption "AgentsView web interface for AI coding agent sessions";

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.agentsview;
          defaultText = lib.literalExpression "inputs.llm-agents.packages.\${pkgs.stdenv.hostPlatform.system}.agentsview";
          description = "The AgentsView package to use.";
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address on which AgentsView listens.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8080;
          description = "Port for the AgentsView web interface.";
        };

        publicUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "https://agentsview.example.com";
          description = "Public URL used for origin validation, or null to omit the argument.";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional command-line arguments passed to AgentsView.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        systemd.user.services.agentsview = {
          Unit.Description = "AgentsView web interface for AI coding agent sessions";

          Service = {
            ExecStart = lib.escapeShellArgs arguments;
            Restart = "on-failure";
            RestartSec = 10;
            WorkingDirectory = "%h";
          };

          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
