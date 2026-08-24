{
  flake.homeManagerModules.moshi =
    {
      self',
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.moshi-hook;
      command = lib.escapeShellArgs (
        [
          (lib.getExe cfg.package)
          "serve"
        ]
        ++ cfg.extraArgs
      );
      servicePath = lib.concatStringsSep ":" (
        lib.optional (cfg.extraPackages != [ ]) (lib.makeBinPath cfg.extraPackages)
        ++ [
          "${config.home.profileDirectory}/bin"
          "/run/current-system/sw/bin"
        ]
      );
    in
    {
      options.services.moshi-hook = {
        enable = lib.mkEnableOption "Moshi agent hook daemon";

        package = lib.mkOption {
          type = lib.types.package;
          default = self'.packages.moshi;
          defaultText = lib.literalExpression "inputs.nixfiles.packages.\${pkgs.stdenv.hostPlatform.system}.moshi";
          description = "The moshi-hook package to use.";
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Additional packages available to moshi-hook.";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional command-line arguments passed to moshi-hook serve.";
        };
      };

      config = lib.mkIf cfg.enable {
        home.packages = [ cfg.package ];

        systemd.user.services.moshi-hook = {
          Unit = {
            Description = "Moshi agent hook daemon";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };

          Service = {
            Environment = "PATH=${servicePath}";
            ExecStart = command;
            Restart = "on-failure";
            RestartSec = 3;
            WorkingDirectory = "%h";
          };

          Install.WantedBy = [ "default.target" ];
        };
      };
    };
}
