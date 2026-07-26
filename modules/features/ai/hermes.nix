{ inputs, lib, ... }:

{
  den.aspects.hermes = {
    settings.hasHostEnv = lib.mkEnableOption "Whether the host has a Hermes environment.";

    nixos =
      {
        self',
        host,
        config,
        pkgs,
        ...
      }:
      let
        hermes = config.services.hermes-agent;
      in
      {
        imports = [ inputs.hermes-agent.nixosModules.default ];

        network.services.hermes = 9119;

        services.hermes-agent = {
          enable = true;

          addToSystemPackages = true;

          environmentFiles = [
            config.sops.secrets.hermes-env.path
          ]
          ++ lib.optional host.settings.hermes.hasHostEnv config.sops.secrets.hermes-env-host.path;

          settings = {
            model.provider = "openai-codex";
            model.default = "gpt-5.6-sol";

            dashboard.theme = "clean-webui";
            dashboard.show_token_analytics = true;

            context.engine = "lcm";

            toolsets = [ "all" ];

            terminal = {
              backend = "local";
              cwd = "/var/lib/hermes/workspace";
            };

            display = {
              show_reasoning = true;
              streaming = true;
              show_cost = true;
              timestamps = true;
            };

            approvals.mode = "smart";

            plugins = {
              enabled = [
                "hermes-lcm"
                # "rtk-rewrite"
              ];
            };
          };

          extraPackages = with pkgs; [
            ffmpeg
            rtk
          ];

          extraPlugins = [
            (pkgs.fetchFromGitHub {
              owner = "stephenschoettler";
              repo = "hermes-lcm";
              rev = "v0.19.0";
              hash = "sha256-B80HCn3BT+M1B8THMm3Ph5tpimTB68yIVkBfPaV4X40=";
            })
          ];

          extraPythonPackages = with pkgs.python312Packages; [
            (
              let
                pname = "rtk-hermes";
                version = "1.2.3";
              in
              buildPythonPackage {
                inherit pname version;
                src = pkgs.fetchFromGitHub {
                  owner = "ogallotti";
                  repo = pname;
                  rev = "v${version}";
                  hash = "sha256-7YRW6PODrCapfYLFn3DvgHAEME//RGC48GQt+s9ot0s=";
                };
                format = "pyproject";
                build-system = [ setuptools ];
              }
            )
          ];

          extraDependencyGroups = [
            "messaging"
            "edge-tts"
            "exa"
            "voice"
            "tts-premium"
          ];

          mcpServers = {
            nixos.command = lib.getExe pkgs.mcp-nixos;
            liftosaur = {
              url = "https://www.liftosaur.com/mcp";
              headers.Authorization = "Bearer \${MCP_LIFTOSAUR_KEY}";
              timeout = 180;
            };
            homeassistant = {
              url = "https://ha.mothership.sucha.foo/api/mcp";
              headers.Authorization = "Bearer \${MCP_HOMEASSISTANT_KEY}";
              timeout = 180;
            };
            github = {
              url = "https://api.githubcopilot.com/mcp";
              headers.Authorization = "Bearer \${MCP_GITHUB_KEY}";
              timeout = 180;
            };
            super-productivity.command = lib.getExe self'.packages.super-productivity-mcp;
          };
        };

        # install the clean-webui theme
        systemd.tmpfiles.rules =
          let
            theme = pkgs.fetchFromGitHub {
              owner = "fplanque";
              repo = "hermes-agent-dashboard-theme-clean";
              rev = "e7d58098f3a3ffc6866e59f4f054fa64c09913e0";
              hash = "sha256-DDBws/rdcwCaUJ2TeGIuaDR0EaDrI0qGs7LhYxHAd9A=";
            };
            clean-webui = "${theme}/clean-webui.yaml";
          in
          [
            "z /var/lib/hermes/.hermes/.env                               0640 ${hermes.user} ${hermes.group} - -" # rw-r-----
            "z /var/lib/hermes/.hermes/config.yaml                        0640 ${hermes.user} ${hermes.group} - -" # rw-r-----
            "z /var/lib/hermes/.hermes/auth.json                          0640 ${hermes.user} ${hermes.group} - -" # rw-r-----
            "z /var/lib/hermes/.hermes/auth.lock                          0660 ${hermes.user} ${hermes.group} - -" # rw-rw----

            "d /var/lib/hermes/.hermes/dashboard-themes                   2770 ${hermes.user} ${hermes.group} - -"
            "C /var/lib/hermes/.hermes/dashboard-themes/clean-webui.yaml  0644 ${hermes.user} ${hermes.group} - ${clean-webui}"
          ];

        systemd.services.hermes-agent = {
          # needed for discord voice channels to work
          # environment.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.libopus ]; # TODO: fix this

          environment.MESSAGING_CWD = lib.mkForce null;

          # fix error from having TimeoutStopSec < drain_timeout + 30s
          serviceConfig.TimeoutStopSec = 30;
        };

        systemd.services.hermes-dashboard = {
          description = "Hermes Agent Web Dashboard";
          path = with pkgs; [ docker ];
          after = [
            "network-online.target"
            "hermes-agent.service"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            User = hermes.user;
            Group = "docker";
            WorkingDirectory = hermes.workingDirectory;
            # Reuse the same managed state/config as the NixOS Hermes service.
            Environment = [
              "HERMES_HOME=${hermes.stateDir}/.hermes"
              "HERMES_MANAGED=true"
            ];
            # Optional: if you keep dashboard auth/env vars in the generated .env.
            EnvironmentFile = "-${hermes.stateDir}/.hermes/.env";
            ExecStart = "${lib.getExe hermes.package} dashboard --host 0.0.0.0 --port ${toString config.network.services.hermes} --no-open";
            Restart = "always";
            RestartSec = 5;
            # Reasonable hardening. Relax if you need the dashboard/chat PTY to access more.
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [
              hermes.stateDir
              hermes.workingDirectory
            ];
          };
        };

        sops.secrets =
          let
            mkHermesSecret = host: {
              sopsFile = ../../../secrets/hosts/${host}/secrets.yaml;
              owner = hermes.user;
              group = hermes.group;
              mode = "0440";
            };
          in
          {
            hermes-env = mkHermesSecret "common";
            hermes-env-host = lib.mkIf host.settings.hermes.hasHostEnv (
              mkHermesSecret config.networking.hostName
            );
          };
      };

    provides.to-users.nixos = { user, ... }: {
      users.users.${user.userName}.extraGroups = [ "hermes" ];
    };

  };

  flake-file.inputs.hermes-agent = {
    url = "github:NousResearch/hermes-agent";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
