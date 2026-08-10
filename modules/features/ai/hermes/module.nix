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

      generatedConfigFile = pkgs.writeText "hermes-config.yaml" (
        builtins.toJSON (lib.recursiveUpdate { terminal.cwd = cfg.workingDirectory; } cfg.settings)
      );

      configMergeScript = pkgs.writeScript "hermes-config-merge" ''
        #!${pkgs.python3.withPackages (pythonPackages: [ pythonPackages.pyyaml ])}/bin/python3
        import json, yaml, sys
        from pathlib import Path

        nix_json, config_path = sys.argv[1], Path(sys.argv[2])

        with open(nix_json) as config_file:
            nix = json.load(config_file)

        existing = {}
        if config_path.exists():
            with open(config_path) as config_file:
                existing = yaml.safe_load(config_file) or {}

        def deep_merge(base, override):
            result = dict(base)
            for key, value in override.items():
                if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                    result[key] = deep_merge(result[key], value)
                else:
                    result[key] = value
            return result

        with open(config_path, "w") as config_file:
            yaml.dump(deep_merge(existing, nix), config_file, default_flow_style=False, sort_keys=False)
      '';

      generatedEnvironmentFile = pkgs.writeText "hermes-environment" (
        lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "${name}=${value}") cfg.environment)
      );

      environmentMergeScript = pkgs.writeShellScript "hermes-environment-merge" ''
        set -eu

        destination="$1"
        shift

        ${pkgs.coreutils}/bin/install -m 0600 ${generatedEnvironmentFile} "$destination"
        for file in "$@"; do
          if [ -f "$file" ]; then
            printf '\n' >> "$destination"
            ${pkgs.coreutils}/bin/cat "$file" >> "$destination"
          fi
        done
      '';

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

      servicePath = lib.makeBinPath (
        [
          cfg.finalPackage
          pkgs.bash
          pkgs.coreutils
          pkgs.git
        ]
        ++ cfg.extraPackages
      );

      mkGatewayService =
        {
          description,
          gatewayHome,
          workingDirectory,
          extraArgs,
          needsNetwork ? false,
        }:
        {
          Unit = {
            Description = description;
          }
          // lib.optionalAttrs needsNetwork {
            Wants = [ "network-online.target" ];
            After = [ "network-online.target" ];
          };

          Service = {
            Environment = [
              "HOME=${config.home.homeDirectory}"
              "HERMES_HOME=${gatewayHome}"
              "HERMES_MANAGED=true"
              "PATH=${servicePath}"
            ];
            ExecStart = lib.escapeShellArgs (
              [
                "${cfg.finalPackage}/bin/hermes"
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
          };

          Install.WantedBy = [ "default.target" ];
        };

      mkProfileGatewayService =
        profile: gateway:
        mkGatewayService {
          description = "Hermes Agent Gateway (${profile} profile)";
          gatewayHome = "${hermesHome}/profiles/${profile}";
          inherit (gateway) workingDirectory extraArgs;
          needsNetwork = true;
        };

      invalidProfileNames = lib.filter (
        profile: profile == "default" || builtins.match "[a-z0-9][a-z0-9_-]{0,63}" profile == null
      ) (builtins.attrNames cfg.profileGateways);
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

        workingDirectory = lib.mkOption {
          type = lib.types.str;
          default = "${hermesHome}/workspace";
          defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/.hermes/workspace"'';
          description = "Working directory for the agent";
        };

        configFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Existing config.yaml to install instead of generating one from settings";
        };

        settings = lib.mkOption {
          type = deepConfigType;
          default = { };
          description = "Declarative Hermes configuration rendered to config.yaml";
          example = lib.literalExpression ''
            {
              model = "anthropic/claude-sonnet-4";
              terminal.backend = "local";
              toolsets = [ "all" ];
            }
          '';
        };

        environmentFiles = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Environment files containing secrets to merge into the Hermes .env file";
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Non-secret environment variables to write to the Hermes .env file";
        };

        authFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "auth.json file to seed when Hermes has no existing authentication state";
        };

        authFileForceOverwrite = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Always overwrite auth.json from authFile";
        };

        documents = lib.mkOption {
          type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.path);
          default = { };
          description = "Workspace documents keyed by filename";
          example = lib.literalExpression ''
            {
              "SOUL.md" = "You are a helpful AI assistant.";
              "USER.md" = ./documents/USER.md;
            }
          '';
        };

        mcpServers = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                command = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "MCP server command for stdio transport";
                };

                args = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "Command-line arguments for stdio transport";
                };

                env = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                  description = "Environment variables for the MCP server process";
                };

                url = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "MCP server URL for HTTP transport";
                };

                headers = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                  description = "HTTP headers for the MCP server";
                };

                auth = lib.mkOption {
                  type = lib.types.nullOr (lib.types.enum [ "oauth" ]);
                  default = null;
                  description = "Authentication method for the MCP server";
                };

                enabled = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Whether to enable the MCP server";
                };

                timeout = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                  description = "Tool call timeout in seconds";
                };

                connect_timeout = lib.mkOption {
                  type = lib.types.nullOr lib.types.int;
                  default = null;
                  description = "Initial connection timeout in seconds";
                };

                tools = lib.mkOption {
                  type = lib.types.nullOr (
                    lib.types.submodule {
                      options = {
                        include = lib.mkOption {
                          type = lib.types.listOf lib.types.str;
                          default = [ ];
                          description = "Tool allowlist";
                        };

                        exclude = lib.mkOption {
                          type = lib.types.listOf lib.types.str;
                          default = [ ];
                          description = "Tool blocklist";
                        };
                      };
                    }
                  );
                  default = null;
                  description = "Filter the tools exposed by this server";
                };

                sampling = lib.mkOption {
                  type = lib.types.nullOr (
                    lib.types.submodule {
                      options = {
                        enabled = lib.mkOption {
                          type = lib.types.bool;
                          default = true;
                          description = "Whether to enable sampling";
                        };

                        model = lib.mkOption {
                          type = lib.types.nullOr lib.types.str;
                          default = null;
                          description = "Model override for sampling requests";
                        };

                        max_tokens_cap = lib.mkOption {
                          type = lib.types.nullOr lib.types.int;
                          default = null;
                          description = "Maximum tokens per sampling request";
                        };

                        timeout = lib.mkOption {
                          type = lib.types.nullOr lib.types.int;
                          default = null;
                          description = "Sampling request timeout in seconds";
                        };

                        max_rpm = lib.mkOption {
                          type = lib.types.nullOr lib.types.int;
                          default = null;
                          description = "Maximum sampling requests per minute";
                        };

                        max_tool_rounds = lib.mkOption {
                          type = lib.types.nullOr lib.types.int;
                          default = null;
                          description = "Maximum tool-use rounds per sampling request";
                        };

                        allowed_models = lib.mkOption {
                          type = lib.types.listOf lib.types.str;
                          default = [ ];
                          description = "Models the server may request";
                        };

                        log_level = lib.mkOption {
                          type = lib.types.nullOr (
                            lib.types.enum [
                              "debug"
                              "info"
                              "warning"
                            ]
                          );
                          default = null;
                          description = "Sampling audit log level";
                        };
                      };
                    }
                  );
                  default = null;
                  description = "Configuration for server-initiated sampling requests";
                };
              };
            }
          );
          default = { };
          description = "MCP server configurations to merge into settings.mcp_servers";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Extra arguments for hermes gateway";
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
              };
            }
          );
          default = { };
          description = "Hermes profile gateways to run as separate user services, keyed by profile name";
          example = lib.literalExpression ''
            {
              assistant = {
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
          (lib.mkIf (cfg.mcpServers != { }) {
            services.hermes-agent.settings.mcp_servers = lib.mapAttrs (
              _name: server:
              lib.optionalAttrs (server.command != null) { inherit (server) command args; }
              // lib.optionalAttrs (server.env != { }) { inherit (server) env; }
              // lib.optionalAttrs (server.url != null) { inherit (server) url; }
              // lib.optionalAttrs (server.headers != { }) { inherit (server) headers; }
              // lib.optionalAttrs (server.auth != null) { inherit (server) auth; }
              // {
                inherit (server) enabled;
              }
              // lib.optionalAttrs (server.timeout != null) { inherit (server) timeout; }
              // lib.optionalAttrs (server.connect_timeout != null) { inherit (server) connect_timeout; }
              // lib.optionalAttrs (server.tools != null) {
                tools = lib.filterAttrs (_name: value: value != [ ]) {
                  inherit (server.tools) include exclude;
                };
              }
              // lib.optionalAttrs (server.sampling != null) {
                sampling = lib.filterAttrs (_name: value: value != null && value != [ ]) {
                  inherit (server.sampling)
                    enabled
                    model
                    max_tokens_cap
                    timeout
                    max_rpm
                    max_tool_rounds
                    allowed_models
                    log_level
                    ;
                };
              }
            ) cfg.mcpServers;
          })

          {
            services.hermes-agent.finalPackage =
              let
                package =
                  if cfg.extraPythonPackages == [ ] && cfg.extraDependencyGroups == [ ] then
                    cfg.package
                  else
                    cfg.package.override { inherit (cfg) extraPythonPackages extraDependencyGroups; };
              in
              if cfg.extraLibraries == [ ] then
                package
              else
                pkgs.symlinkJoin {
                  name = "${package.name}-with-extra-libraries";
                  inherit (package) meta passthru;
                  paths = [ package ];
                  nativeBuildInputs = [ pkgs.makeWrapper ];
                  postBuild = ''
                    for executable in "$out"/bin/*; do
                      wrapProgram "$executable" \
                        --prefix LD_LIBRARY_PATH : ${lib.escapeShellArg (lib.makeLibraryPath cfg.extraLibraries)} \
                        --prefix PATH : ${lib.escapeShellArg (lib.makeBinPath [ pkgs.binutils ])}
                    done
                  '';
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
              ];

            home = {
              packages = [ cfg.finalPackage ] ++ cfg.extraPackages;
              sessionVariables.HERMES_HOME = hermesHome;

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
                      ${lib.escapeShellArg "${hermesHome}/cron"} \
                      ${lib.escapeShellArg "${hermesHome}/logs"} \
                      ${lib.escapeShellArg "${hermesHome}/memories"} \
                      ${lib.escapeShellArg "${hermesHome}/plugins"} \
                      ${lib.escapeShellArg "${hermesHome}/sessions"} \
                      ${lib.escapeShellArg cfg.workingDirectory}
                    run chmod 0700 ${lib.escapeShellArg hermesHome}

                    ${
                      if cfg.configFile != null then
                        "run install -m 0600 ${lib.escapeShellArg (toString cfg.configFile)} ${lib.escapeShellArg "${hermesHome}/config.yaml"}"
                      else
                        ''
                          run ${configMergeScript} ${generatedConfigFile} ${lib.escapeShellArg "${hermesHome}/config.yaml"}
                          run chmod 0600 ${lib.escapeShellArg "${hermesHome}/config.yaml"}
                        ''
                    }

                    run touch ${lib.escapeShellArg "${hermesHome}/.managed"}
                    run chmod 0600 ${lib.escapeShellArg "${hermesHome}/.managed"}

                    ${lib.optionalString (cfg.authFile != null) (
                      if cfg.authFileForceOverwrite then
                        "run install -m 0600 ${lib.escapeShellArg (toString cfg.authFile)} ${lib.escapeShellArg "${hermesHome}/auth.json"}"
                      else
                        ''
                          if [ ! -f ${lib.escapeShellArg "${hermesHome}/auth.json"} ]; then
                            run install -m 0600 ${lib.escapeShellArg (toString cfg.authFile)} ${lib.escapeShellArg "${hermesHome}/auth.json"}
                          fi
                        ''
                    )}

                    ${lib.optionalString (cfg.environment != { } || cfg.environmentFiles != [ ]) ''
                      run ${environmentMergeScript} ${lib.escapeShellArg "${hermesHome}/.env"} ${lib.escapeShellArgs cfg.environmentFiles}
                    ''}

                    ${lib.concatStringsSep "\n" (
                      lib.mapAttrsToList (name: _value: ''
                        run install -m 0600 ${lib.escapeShellArg "${documents}/${name}"} ${lib.escapeShellArg "${cfg.workingDirectory}/${name}"}
                      '') cfg.documents
                    )}

                    run find ${lib.escapeShellArg "${hermesHome}/plugins"} -maxdepth 1 -type l -name 'nix-managed-*' -delete
                    ${lib.concatMapStringsSep "\n" (plugin: ''
                      if [ ! -f ${lib.escapeShellArg "${plugin}/plugin.yaml"} ]; then
                        echo "extraPlugins entry '${plugin}' has no plugin.yaml" >&2
                        exit 1
                      fi
                      run ln -sfn ${lib.escapeShellArg (toString plugin)} ${lib.escapeShellArg "${hermesHome}/plugins/nix-managed-${lib.getName plugin}"}
                    '') cfg.extraPlugins}
                  '';
            };

            systemd.user.services = {
              hermes-agent = mkGatewayService {
                description = "Hermes Agent Gateway";
                gatewayHome = hermesHome;
                inherit (cfg) workingDirectory extraArgs;
              };
            }
            // lib.mapAttrs' (
              profile: gateway:
              lib.nameValuePair "hermes-agent-${profile}" (mkProfileGatewayService profile gateway)
            ) cfg.profileGateways;
          }

          (lib.mkIf cfg.dashboard.enable {
            systemd.user.services.hermes-dashboard = {
              Unit = {
                Description = "Hermes Agent Web Dashboard";
                After = [ "hermes-agent.service" ];
              };

              Service = {
                Environment = [
                  "HERMES_HOME=${hermesHome}"
                  "HERMES_MANAGED=true"
                ];
                EnvironmentFile = "-${hermesHome}/.env";
                ExecStart = lib.escapeShellArgs [
                  (lib.getExe cfg.finalPackage)
                  "dashboard"
                  "--host"
                  cfg.dashboard.host
                  "--port"
                  (toString cfg.dashboard.port)
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

              Install.WantedBy = [ "default.target" ];
            };
          })

        ]
      );
    };
}
