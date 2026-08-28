{
  flake.homeManagerModules.collie =
    {
      self',
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.collie;
      reservedEnvironment = [
        "COLLIE_PORT"
        "COLLIE_PUBLIC_HOSTS"
        "COLLIE_SKIP_SERVE"
        "COLLIE_STATE_DIR"
        "HERDR_PLUGIN_CONFIG_DIR"
        "HERDR_SOCKET_PATH"
      ];
      environment = cfg.environment // {
        COLLIE_PORT = toString cfg.port;
        COLLIE_PUBLIC_HOSTS = lib.concatStringsSep "," cfg.publicHosts;
        COLLIE_SKIP_SERVE = "1";
        COLLIE_STATE_DIR = cfg.stateDirectory;
        HERDR_PLUGIN_CONFIG_DIR = cfg.configDirectory;
        HERDR_SOCKET_PATH = cfg.herdrSocketPath;
      };
      serviceEnvironment = lib.mapAttrsToList (name: value: "${name}=${value}") environment;
      environmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
    in
    {
      options.services.collie = {
        enable = lib.mkEnableOption "Collie web interface for Herdr";

        package = lib.mkOption {
          type = lib.types.package;
          default = self'.packages.collie;
          defaultText = lib.literalExpression "inputs.nixfiles.packages.\${pkgs.stdenv.hostPlatform.system}.collie";
          description = "The Collie package to use.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 8787;
          description = "TCP port on which Collie listens.";
        };

        herdrSocketPath = lib.mkOption {
          type = lib.types.str;
          default = "${config.xdg.configHome}/herdr/herdr.sock";
          description = "Path to the Herdr socket.";
        };

        configDirectory = lib.mkOption {
          type = lib.types.str;
          default = "${config.xdg.configHome}/collie";
          description = "Directory containing Collie operator configuration.";
        };

        stateDirectory = lib.mkOption {
          type = lib.types.str;
          default = "${config.xdg.stateHome}/collie";
          description = "Directory in which Collie stores runtime state.";
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Required systemd environment file for secrets and additional Collie settings, or null for none.";
        };

        publicHosts = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Host names accepted by Collie's Host-header validation.";
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Additional environment variables passed to Collie and its control script.";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = lib.intersectLists reservedEnvironment (builtins.attrNames cfg.environment) == [ ];
            message = "services.collie.environment cannot override settings with dedicated module options.";
          }
        ];

        home.packages = [ cfg.package ];

        systemd.user.services = {
          collie = {
            Unit = {
              Description = "Collie web interface for Herdr";
              After = [ "network-online.target" ];
              Wants = [ "network-online.target" ];
              StartLimitIntervalSec = 0;
            };

            Service = {
              Environment = serviceEnvironment;
              EnvironmentFile = environmentFile;
              ExecStartPre = lib.escapeShellArgs [
                "${pkgs.coreutils}/bin/mkdir"
                "-p"
                cfg.configDirectory
                cfg.stateDirectory
              ];
              ExecStart = lib.getExe cfg.package;
              NoNewPrivileges = true;
              PrivateTmp = true;
              Restart = "on-failure";
              RestartSec = 5;
              UMask = "0077";
              WorkingDirectory = "${cfg.package}/lib/collie";
            };

            Install.WantedBy = [ "default.target" ];
          };
        };
      };
    };
}
