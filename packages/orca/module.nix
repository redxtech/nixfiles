{ self, ... }:

{
  flake.homeManagerModules.orca =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.orca;
      arguments = [
        (lib.getExe' cfg.package "orca-server")
        "--port"
        (toString cfg.port)
      ]
      ++ lib.optionals (cfg.pairingAddress != null) [
        "--pairing-address"
        cfg.pairingAddress
      ]
      ++ lib.optionals (cfg.projectRoot != null) [
        "--project-root"
        cfg.projectRoot
      ]
      ++ cfg.extraArgs;
      command = lib.escapeShellArgs arguments;
      launcher = pkgs.writeShellScript "orca-server" ''
        export PATH="${lib.makeBinPath cfg.extraPackages}''${PATH:+:$PATH}"
        exec ${command}
      '';
    in
    {
      options.services.orca = {
        enable = lib.mkEnableOption "Orca headless runtime server";

        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.orca;
          defaultText = lib.literalExpression "self.packages.\${pkgs.stdenv.hostPlatform.system}.orca";
          description = "The Orca package to use.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 6768;
          description = "Port on which the Orca runtime server listens.";
        };

        pairingAddress = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "100.64.1.20";
          description = "Reachable address advertised to clients, or null to use Orca's default.";
        };

        projectRoot = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "/home/me/src/project";
          description = "Absolute project directory exposed by the server, or null for no initial project.";
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Additional packages, such as coding-agent CLIs, available to Orca.";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional command-line arguments passed to orca serve.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        systemd.user.services.orca = {
          Unit = {
            Description = "Orca headless runtime server";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
            StartLimitIntervalSec = 300;
            StartLimitBurst = 5;
          };

          Service = {
            ExecStart = if cfg.extraPackages == [ ] then command else launcher;
            Environment = [ "LIBGL_ALWAYS_SOFTWARE=1" ];
            Restart = "on-failure";
            RestartPreventExitStatus = 3;
            RestartSec = 5;
            WorkingDirectory = if cfg.projectRoot == null then "%h" else cfg.projectRoot;
          };

          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
