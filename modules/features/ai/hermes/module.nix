{ inputs, ... }:

{
  flake.homeManagerModules.hermes =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.hermes-agent;
      hermesHome = "${config.home.homeDirectory}/.hermes";

      deepConfigType = lib.types.mkOptionType {
        name = "hermes-config-attrs";
        description = "Hermes YAML configuration, merged recursively";
        check = builtins.isAttrs;
        merge =
          _location: definitions:
          lib.foldl' lib.recursiveUpdate { } (map (definition: definition.value) definitions);
      };

      yamlFormat = pkgs.formats.yaml { };
      managedConfigFile = yamlFormat.generate "hermes-managed-config.yaml" cfg.managedSettings;
      managedDirectory = pkgs.linkFarm "hermes-managed-scope" [
        {
          name = "config.yaml";
          path = managedConfigFile;
        }
      ];
      managedSkillsDirectory = pkgs.linkFarm "hermes-managed-skills" (
        lib.mapAttrsToList (name: path: { inherit name path; }) cfg.managedSkills
      );
      documents = pkgs.linkFarm "hermes-documents" (
        lib.mapAttrsToList (name: value: {
          inherit name;
          path =
            if builtins.isPath value || lib.isStorePath value then
              value
            else
              pkgs.writeText "hermes-document-${builtins.baseNameOf name}" value;
        }) cfg.documents
      );

      hermesEnvironmentLoader =
        pkgs.writers.writePython3Bin "hermes-environment-loader"
          {
            libraries = [ pkgs.python3Packages.python-dotenv ];
            flakeIgnore = [ "E501" ];
          }
          ''
            import os
            import sys
            from pathlib import Path

            from dotenv import dotenv_values

            for environment_file in ${builtins.toJSON cfg.environmentFiles}:
                path = Path(environment_file)
                if not path.is_file():
                    raise SystemExit(f"Hermes environment file is missing: {path}")
                for name, value in dotenv_values(path).items():
                    if value is not None:
                        os.environ[name] = value

            os.environ["HERMES_MANAGED_DIR"] = ${builtins.toJSON (toString cfg.managedDirectory)}
            executable = ${builtins.toJSON (lib.getExe cfg.finalPackage)}
            os.execv(executable, [executable, *sys.argv[1:]])
          '';

      pythonEnvironmentVariables = [
        "PYTHONHOME"
        "PYTHONPATH"
        "PYTHONUSERBASE"
        "VIRTUAL_ENV"
      ];

      interactiveHermes = pkgs.writeShellScriptBin "hermes" ''
        unset ${lib.escapeShellArgs pythonEnvironmentVariables}
        exec ${lib.getExe hermesEnvironmentLoader} "$@"
      '';

      hermesConfigMigrator = pkgs.writeShellScriptBin "hermes-config-migrate-noninteractive" ''
        unset ${lib.escapeShellArgs pythonEnvironmentVariables}
        exec ${cfg.finalPackage.hermesVenv}/bin/python3 -c \
          'from hermes_cli.config import migrate_config; migrate_config(interactive=False, quiet=True)'
      '';

      mkGatewayHermes =
        name: port:
        pkgs.writeShellScriptBin name ''
          export API_SERVER_PORT=${lib.escapeShellArg (toString port)}
          exec ${lib.getExe cfg.finalPackage} "$@"
        '';

      servicePath = lib.makeBinPath (
        [
          cfg.finalPackage
          pkgs.bash
          pkgs.coreutils
          pkgs.git
        ]
        ++ cfg.extraPackages
      );

      serviceEnvironment =
        gatewayHome: extraEnvironment:
        [
          "HOME=${config.home.homeDirectory}"
          "HERMES_HOME=${gatewayHome}"
          "PATH=${servicePath}"
        ]
        ++ lib.mapAttrsToList (name: value: "${name}=${value}") cfg.environment
        ++ lib.mapAttrsToList (name: value: "${name}=${value}") extraEnvironment
        ++ [ "HERMES_MANAGED_DIR=${cfg.managedDirectory}" ];
      formatSocketAddress =
        host: port:
        let
          bareHost = lib.removePrefix "[" (lib.removeSuffix "]" host);
          formattedHost = if lib.hasInfix ":" bareHost then "[${bareHost}]" else bareHost;
        in
        "${formattedHost}:${toString port}";
      # Hermes derives its authentication and Host-header policy from the bind host, so the
      # backend must retain the configured host even though wildcard listeners are dialed via loopback.
      dashboardBackendHost =
        if cfg.dashboard.host == "0.0.0.0" then
          "127.0.0.1"
        else if cfg.dashboard.host == "::" then
          "::1"
        else
          cfg.dashboard.host;
      dashboardSocketAddress = formatSocketAddress cfg.dashboard.host cfg.dashboard.port;
      dashboardBackendAddress = formatSocketAddress dashboardBackendHost cfg.dashboard.backendPort;
      dashboardReadyCheck = pkgs.writeShellScript "wait-for-hermes-dashboard" ''
        for _attempt in {1..300}; do
          if (exec 3<>"/dev/tcp/${dashboardBackendHost}/${toString cfg.dashboard.backendPort}") 2>/dev/null; then
            exit 0
          fi
          ${pkgs.coreutils}/bin/sleep 0.1
        done

        echo "Hermes dashboard did not become ready at ${dashboardBackendAddress}" >&2
        exit 1
      '';

      mkGatewayService =
        {
          name,
          description,
          gatewayHome,
          workingDirectory,
          extraArgs,
          port,
          environment ? { },
          unsetEnvironment ? [ ],
          needsNetwork ? false,
        }:
        let
          gatewayHermes = mkGatewayHermes name port;
          gatewayEnvironment = environment // {
            API_SERVER_PORT = toString port;
          };
        in
        {
          Unit = {
            Description = description;
            ConditionPathExists = [ "!${hermesHome}/.managed" ];
          }
          // lib.optionalAttrs needsNetwork {
            Wants = [ "network-online.target" ];
            After = [ "network-online.target" ];
          };

          Service = {
            Environment = serviceEnvironment gatewayHome gatewayEnvironment;
            EnvironmentFile = cfg.environmentFiles;
            ExecStart = lib.escapeShellArgs (
              [
                (lib.getExe gatewayHermes)
                "gateway"
              ]
              ++ extraArgs
            );
            Restart = "always";
            RestartSec = 5;
            TimeoutStopSec = 30;
            WorkingDirectory = workingDirectory;
            UMask = "0077";

            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectHome = false;
            ProtectSystem = "strict";
            ReadWritePaths = [
              gatewayHome
              workingDirectory
            ];
          }
          // lib.optionalAttrs (unsetEnvironment != [ ]) { UnsetEnvironment = unsetEnvironment; };

          Install.WantedBy = [ "default.target" ];
        };

      mkProfileGatewayService =
        profile: gateway:
        mkGatewayService {
          name = "hermes-agent-${profile}";
          description = "Hermes Agent Gateway (${profile} profile)";
          gatewayHome = "${hermesHome}/profiles/${profile}";
          inherit (gateway)
            workingDirectory
            extraArgs
            port
            environment
            ;
          needsNetwork = true;
        };

      gatewayPorts =
        lib.optional cfg.gateway.enable cfg.gateway.port
        ++ lib.mapAttrsToList (_profile: gateway: gateway.port) cfg.profileGateways;
      servicePorts =
        gatewayPorts
        ++ lib.optionals cfg.dashboard.enable [
          cfg.dashboard.port
          cfg.dashboard.backendPort
        ];
      invalidProfileNames = lib.filter (
        profile: profile == "default" || builtins.match "[a-z0-9][a-z0-9_-]{0,63}" profile == null
      ) (builtins.attrNames cfg.profileGateways);
      isSinglePathComponent =
        name: name != "" && name != "." && name != ".." && builtins.baseNameOf name == name;
      invalidDocumentNames = lib.filter (name: !(isSinglePathComponent name)) (
        builtins.attrNames cfg.documents
      );
      invalidManagedSkillNames = lib.filter (name: !(isSinglePathComponent name)) (
        builtins.attrNames cfg.managedSkills
      );

      linkPlugins = pluginDirectory: ''
        run mkdir -p ${lib.escapeShellArg pluginDirectory}
        run find ${lib.escapeShellArg pluginDirectory} -maxdepth 1 -type l -name 'nix-managed-*' -delete
        ${lib.concatMapStringsSep "\n" (plugin: ''
          if [ ! -f ${lib.escapeShellArg "${plugin}/plugin.yaml"} ]; then
            echo "extraPlugins entry '${plugin}' has no plugin.yaml" >&2
            exit 1
          fi
          run ln -sfn ${lib.escapeShellArg (toString plugin)} ${lib.escapeShellArg "${pluginDirectory}/nix-managed-${lib.getName plugin}"}
        '') cfg.extraPlugins}
      '';
    in
    {
      options.services.hermes-agent = {
        enable = lib.mkEnableOption "Hermes Agent gateway service";

        dashboard = {
          enable = lib.mkEnableOption "Hermes Agent web dashboard";

          port = lib.mkOption {
            type = lib.types.port;
            default = 9119;
            description = "Port used by the Hermes Agent web dashboard";
          };

          host = lib.mkOption {
            type = lib.types.str;
            default = "0.0.0.0";
            description = "Host used by the Hermes Agent web dashboard";
          };

          backendPort = lib.mkOption {
            type = lib.types.port;
            default = 19119;
            description = "Port used by the Hermes Agent web dashboard behind its socket proxy";
          };

          idleTimeout = lib.mkOption {
            type = lib.types.str;
            default = "5min";
            description = "Time without dashboard connections before stopping its socket proxy and backend";
          };
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default;
          defaultText = lib.literalExpression "inputs.hermes-agent.packages.\${pkgs.stdenv.hostPlatform.system}.default";
          description = "The hermes-agent package to use";
        };

        finalPackage = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "The hermes-agent package after applying package extensions";
        };

        desktopPackage = lib.mkOption {
          type = lib.types.package;
          readOnly = true;
          description = "Hermes Desktop configured to launch the managed interactive wrapper";
        };

        workingDirectory = lib.mkOption {
          type = lib.types.str;
          default = "${hermesHome}/workspace";
          defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.hermes/workspace"'';
          description = "Working directory for the agent";
        };

        managedDirectory = lib.mkOption {
          type = lib.types.path;
          readOnly = true;
          description = "Generated directory containing the Nix-owned Hermes managed configuration";
        };

        managedSettings = lib.mkOption {
          type = deepConfigType;
          default = { };
          description = "Selective Nix-owned Hermes configuration rendered through managed scope";
        };

        managedSkills = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          default = { };
          description = "Read-only skills exposed to Hermes through managed scope";
        };

        documents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.path);
          default = { };
          description = "Nix-owned workspace documents keyed by filename";
        };

        environmentFiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Environment files containing secrets for Hermes services";
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Non-secret environment variables for Hermes services and interactive shells";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra arguments for the default Hermes gateway";
        };

        gateway = {
          enable = lib.mkEnableOption "the default Hermes gateway" // {
            default = true;
          };

          port = lib.mkOption {
            type = lib.types.port;
            default = 8642;
            description = "API server port for the default Hermes gateway";
          };

          environment = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            description = "Environment overrides for the default Hermes gateway";
          };

          unsetEnvironment = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Environment variables to remove from the default Hermes gateway after loading environment files";
          };
        };

        profileGateways = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                workingDirectory = lib.mkOption {
                  type = lib.types.str;
                  description = "Working directory for this profile's gateway";
                };

                extraArgs = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Extra arguments for this profile's gateway";
                };

                port = lib.mkOption {
                  type = lib.types.port;
                  description = "API server port for this profile's gateway";
                };

                environment = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                  description = "Environment overrides for this profile's gateway";
                };

              };
            }
          );
          default = { };
          description = "Hermes profile gateways to run as separate user services, keyed by profile name";
          example = lib.literalExpression ''
            {
              assistant = {
                port = 8643;
                workingDirectory = "''${config.home.homeDirectory}/Documents/personal";
                extraArgs = [
                  "run"
                  "--replace"
                  "--external-supervisor"
                ];
              };
            }
          '';
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Extra packages available to Hermes and its terminal sessions";
        };

        extraLibraries = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Shared libraries available to Hermes processes";
        };

        extraPlugins = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Directory-based plugins to link into the Hermes plugin directory";
        };

        extraPythonPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Python packages to add for entry-point plugin discovery";
        };

        extraDependencyGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional hermes-agent optional dependency groups";
        };
      };

      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            services.hermes-agent = {
              finalPackage =
                let
                  package =
                    if cfg.extraPythonPackages == [ ] && cfg.extraDependencyGroups == [ ] then
                      cfg.package
                    else
                      cfg.package.override { inherit (cfg) extraPythonPackages extraDependencyGroups; };
                  wrapperArguments =
                    lib.concatMap (variable: [
                      "--unset"
                      variable
                    ]) pythonEnvironmentVariables
                    ++ lib.optionals (cfg.extraLibraries != [ ]) [
                      "--prefix"
                      "LD_LIBRARY_PATH"
                      ":"
                      (lib.makeLibraryPath cfg.extraLibraries)
                      "--prefix"
                      "PATH"
                      ":"
                      (lib.makeBinPath [ pkgs.binutils ])
                    ];
                in
                pkgs.symlinkJoin {
                  name = "${package.name}-isolated";
                  inherit (package) meta passthru;
                  paths = [ package ];
                  nativeBuildInputs = [ pkgs.makeWrapper ];
                  postBuild = ''
                    for executable in "$out"/bin/*; do
                      wrapProgram "$executable" ${lib.escapeShellArgs wrapperArguments}
                    done
                  '';
                };

              desktopPackage = cfg.finalPackage.hermesDesktop.override { hermesAgent = interactiveHermes; };

              inherit managedDirectory;
              managedSettings = lib.optionalAttrs (cfg.managedSkills != { }) {
                skills.external_dirs = [ (toString managedSkillsDirectory) ];
              };
            };

            assertions =
              let
                pluginNames = map lib.getName cfg.extraPlugins;
              in
              [
                {
                  assertion = builtins.length pluginNames == builtins.length (lib.unique pluginNames);
                  message = "services.hermes-agent.extraPlugins contains duplicate plugin names: ${toString pluginNames}";
                }
                {
                  assertion = invalidProfileNames == [ ];
                  message = "services.hermes-agent.profileGateways contains invalid profile names: ${toString invalidProfileNames}; names must match [a-z0-9][a-z0-9_-]{0,63} and must not be default";
                }
                {
                  assertion = builtins.length servicePorts == builtins.length (lib.unique servicePorts);
                  message = "services.hermes-agent service ports must be unique: ${toString servicePorts}";
                }
                {
                  assertion = invalidDocumentNames == [ ];
                  message = "services.hermes-agent.documents contains invalid filenames: ${toString invalidDocumentNames}";
                }
                {
                  assertion = invalidManagedSkillNames == [ ];
                  message = "services.hermes-agent.managedSkills contains invalid skill names: ${toString invalidManagedSkillNames}";
                }
                {
                  assertion = !(cfg.environment ? HERMES_MANAGED);
                  message = "services.hermes-agent.environment must not set HERMES_MANAGED because Hermes configuration is mutable";
                }
              ];

            home = {
              packages = [ interactiveHermes ] ++ cfg.extraPackages;
              sessionVariables = cfg.environment // {
                HERMES_HOME = hermesHome;
                HERMES_MANAGED_DIR = cfg.managedDirectory;
              };

              file.".config/hermes-agent/nix-mutable-config-v1".text = ''
                HERMES_MANAGED_DIR=${cfg.managedDirectory}
                HERMES_EXECUTABLE=${lib.getExe interactiveHermes}
                HERMES_CONFIG_MIGRATOR=${lib.getExe hermesConfigMigrator}
              '';

              activation.hermes-agent-setup =
                lib.hm.dag.entryBetween
                  [ "reloadSystemd" ]
                  [
                    "writeBoundary"
                    "sops-nix"
                  ]
                  ''
                    run mkdir -p \
                      ${lib.escapeShellArg hermesHome} \
                      ${lib.escapeShellArg cfg.workingDirectory}
                    run chmod 0700 ${lib.escapeShellArg hermesHome}

                    ${lib.concatStringsSep "\n" (
                      lib.mapAttrsToList (profile: gateway: ''
                        run mkdir -p \
                          ${lib.escapeShellArg "${hermesHome}/profiles/${profile}"} \
                          ${lib.escapeShellArg gateway.workingDirectory}
                        run chmod 0700 ${lib.escapeShellArg "${hermesHome}/profiles/${profile}"}
                        ${linkPlugins "${hermesHome}/profiles/${profile}/plugins"}
                      '') cfg.profileGateways
                    )}

                    ${lib.concatStringsSep "\n" (
                      lib.mapAttrsToList (name: _value: ''
                        run install -m 0600 ${lib.escapeShellArg "${documents}/${name}"} ${lib.escapeShellArg "${cfg.workingDirectory}/${name}"}
                      '') cfg.documents
                    )}

                    ${linkPlugins "${hermesHome}/plugins"}
                  '';
            };

            systemd.user.services =
              lib.optionalAttrs cfg.gateway.enable {
                hermes-agent = mkGatewayService {
                  name = "hermes-agent";
                  description = "Hermes Agent Gateway";
                  gatewayHome = hermesHome;
                  inherit (cfg) workingDirectory extraArgs;
                  inherit (cfg.gateway)
                    port
                    environment
                    unsetEnvironment
                    ;
                };
              }
              // lib.mapAttrs' (
                profile: gateway:
                lib.nameValuePair "hermes-agent-${profile}" (mkProfileGatewayService profile gateway)
              ) cfg.profileGateways;
          }

          (lib.mkIf cfg.dashboard.enable {
            systemd.user = {
              sockets.hermes-dashboard = {
                Unit = {
                  Description = "Hermes Agent Web Dashboard Socket";
                  ConditionPathExists = [ "!${hermesHome}/.managed" ];
                };

                Socket = {
                  ListenStream = dashboardSocketAddress;
                  Service = "hermes-dashboard-proxy.service";
                };

                Install.WantedBy = [ "sockets.target" ];
              };

              services = {
                hermes-dashboard = {
                  Unit = {
                    Description = "Hermes Agent Web Dashboard";
                    After = lib.optional cfg.gateway.enable "hermes-agent.service";
                    ConditionPathExists = [ "!${hermesHome}/.managed" ];
                    StopWhenUnneeded = true;
                  };

                  Service = {
                    Environment = serviceEnvironment hermesHome { };
                    EnvironmentFile = cfg.environmentFiles;
                    ExecStart = lib.escapeShellArgs [
                      (lib.getExe cfg.finalPackage)
                      "dashboard"
                      "--host"
                      cfg.dashboard.host
                      "--port"
                      (toString cfg.dashboard.backendPort)
                      "--no-open"
                    ];
                    Restart = "always";
                    RestartSec = 5;
                    WorkingDirectory = cfg.workingDirectory;

                    NoNewPrivileges = true;
                    PrivateTmp = true;
                    ProtectHome = false;
                    ProtectSystem = "strict";
                    ReadWritePaths = [
                      hermesHome
                      cfg.workingDirectory
                    ];
                  };
                };

                hermes-dashboard-proxy = {
                  Unit = {
                    Description = "Hermes Agent Web Dashboard Socket Proxy";
                    Requires = [
                      "hermes-dashboard.service"
                      "hermes-dashboard.socket"
                    ];
                    After = [
                      "hermes-dashboard.service"
                      "hermes-dashboard.socket"
                    ];
                    ConditionPathExists = [ "!${hermesHome}/.managed" ];
                  };

                  Service = {
                    ExecStartPre = dashboardReadyCheck;
                    ExecStart = lib.escapeShellArgs [
                      "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd"
                      "--exit-idle-time=${cfg.dashboard.idleTimeout}"
                      dashboardBackendAddress
                    ];
                    Restart = "on-failure";
                    RestartSec = 1;

                    NoNewPrivileges = true;
                    PrivateTmp = true;
                    ProtectHome = true;
                    ProtectSystem = "strict";
                  };
                };
              };
            };
          })

        ]
      );
    };
}
