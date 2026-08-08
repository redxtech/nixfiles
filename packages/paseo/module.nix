{ self, ... }:

{
  flake.homeManagerModules.paseo =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.paseo;
    in
    {
      options.services.paseo = {
        enable = lib.mkEnableOption "Paseo agent orchestration server";

        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.paseo;
          defaultText = lib.literalExpression "self.packages.\${pkgs.stdenv.hostPlatform.system}.paseo";
          description = "The Paseo package to use.";
        };

        host = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1";
          description = "Address on which the Paseo server listens.";
        };

        hostnames = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Hostnames on which the Paseo server listens.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 6767;
          description = "Port on which the Paseo server listens.";
        };

        webUi.enable = lib.mkEnableOption "the bundled Paseo web interface";
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        systemd.user.services.paseo = {
          Unit.Description = "Paseo agent orchestration server";

          Service = {
            Environment = [
              "PASEO_LISTEN=${cfg.host}:${toString cfg.port}"
              "PASEO_WEB_UI_ENABLED=${lib.boolToString cfg.webUi.enable}"
            ]
            ++ lib.optionals (cfg.hostnames != [ ]) [
              "PASEO_HOSTNAMES=${lib.concatStringsSep "," cfg.hostnames}"
            ];
            ExecStart = lib.getExe' cfg.package "paseo-server";
            Restart = "on-failure";
            RestartSec = 5;
            WorkingDirectory = "%h";
          };

          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
