{ self, ... }:

{
  flake.homeManagerModules.workspace-mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.workspace-mcp;
      workspaceServices = [
        "appscript"
        "calendar"
        "chat"
        "contacts"
        "docs"
        "drive"
        "forms"
        "gmail"
        "search"
        "sheets"
        "slides"
        "tasks"
      ];
      arguments = [
        (lib.getExe cfg.package)
        "--transport"
        "streamable-http"
      ]
      ++ lib.optionals (cfg.toolTier != null) [
        "--tool-tier"
        cfg.toolTier
      ]
      ++ lib.optionals (cfg.tools != null) ([ "--tools" ] ++ cfg.tools)
      ++ lib.optional cfg.readOnly "--read-only"
      ++ lib.optionals (cfg.permissions != [ ]) ([ "--permissions" ] ++ cfg.permissions)
      ++ cfg.extraArgs;
      environment = cfg.environment // {
        WORKSPACE_MCP_HOST = cfg.host;
        WORKSPACE_MCP_PORT = toString cfg.port;
      };
    in
    {
      options.services.workspace-mcp = {
        enable = lib.mkEnableOption "Google Workspace MCP server";

        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.workspace-mcp;
          defaultText = lib.literalExpression "inputs.nixflake-redxtech.packages.\${pkgs.stdenv.hostPlatform.system}.workspace-mcp";
          description = "The workspace-mcp package to use.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8000;
          description = "Port on which the MCP server listens.";
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address on which the MCP server listens.";
        };

        toolTier = lib.mkOption {
          type = lib.types.nullOr (
            lib.types.enum [
              "core"
              "extended"
              "complete"
            ]
          );
          default = null;
          example = "core";
          description = "Tool tier to load, or null to use the upstream default.";
        };

        tools = lib.mkOption {
          type = lib.types.nullOr (lib.types.listOf (lib.types.enum workspaceServices));
          default = null;
          example = [
            "calendar"
            "gmail"
          ];
          description = "Workspace services to enable, or null to enable all services.";
        };

        readOnly = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to request only read-only scopes and disable write tools.";
        };

        permissions = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "gmail:organize"
            "drive:readonly"
          ];
          description = "Granular service permissions in service:level form.";
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example.WORKSPACE_EXTERNAL_URL = "https://workspace.example.com";
          description = "Non-secret environment variables for workspace-mcp.";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "--single-user" ];
          description = "Additional command-line arguments passed to workspace-mcp.";
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/run/secrets/workspace-mcp";
          description = "Environment file containing credentials and other secrets for workspace-mcp.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = cfg.permissions == [ ] || !cfg.readOnly;
            message = "services.workspace-mcp.permissions cannot be combined with readOnly.";
          }
          {
            assertion = cfg.permissions == [ ] || cfg.tools == null;
            message = "services.workspace-mcp.permissions cannot be combined with tools.";
          }
        ];

        home.packages = [ cfg.package ];

        systemd.user.services.workspace-mcp = {
          Unit = {
            Description = "Google Workspace MCP server";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            ExecStart = lib.escapeShellArgs arguments;
            Restart = "on-failure";
            Environment = lib.mapAttrsToList (name: value: "${name}=${value}") environment;
            EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
          };

          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
