{ self, ... }:

{
  den.aspects.hermes = {
    nixos = { host, config, ... }: {
      network.services.hermes =
        config.home-manager.users.${host.settings.base.primaryUser}.services.hermes-agent.dashboard.port;

      # enable accessibility service for hermes computer_use skill
      services.gnome.at-spi2-core.enable = true;
      systemd.user.services.at-spi-dbus-bus.wantedBy = [ "graphical-session.target" ];
    };

    homeManager =
      {
        self',
        inputs',
        config,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ self.homeManagerModules.hermes ];

        services.hermes-agent = {
          enable = true;
          workingDirectory = "${config.home.homeDirectory}/Documents/personal";
          extraArgs = [
            "run"
            "--replace"
            "--external-supervisor"
          ];

          dashboard.enable = true;
          gateway.port = 8642;

          managedSkills = config.ai.finalSkills;
          documents."AGENTS.md" = config.ai.contextFile;

          managedSettings = {
            plugins.enabled = [
              "hermes-lcm"
              "rtk-rewrite"
            ];

            mcp_servers = {
              codebase-memory.command = lib.getExe self'.packages.codebase-memory-mcp;
              nixos.command = lib.getExe pkgs.mcp-nixos;
              super-productivity.command = lib.getExe self'.packages.super-productivity-mcp;
              fastmail = {
                url = "https://api.fastmail.com/mcp";
                headers.Authorization = "Bearer \${MCP_FASTMAIL_KEY}";
                timeout = 180;
              };
              strava.command = lib.getExe self'.packages.strava-mcp;
              liftosaur = {
                url = "https://www.liftosaur.com/mcp";
                headers.Authorization = "Bearer \${MCP_LIFTOSAUR_KEY}";
                timeout = 180;
              };
              kagi = {
                url = "https://mcp.kagi.com/mcp";
                headers.Authorization = "Bearer \${MCP_KAGI_KEY}";
                timeout = 180;
              };
              karakeep = {
                command = lib.getExe self'.packages.karakeep-mcp;
                env = {
                  KARAKEEP_API_ADDR = "https://karakeep.super.fish";
                  KARAKEEP_API_KEY = "\${MCP_KARAKEEP_KEY}";
                };
              };
            };
          };

          environmentFiles = [ config.sops.secrets."hermes.env".path ];
          environment.CUA_DRIVER_RS_ENABLE_WAYLAND = "1";

          extraPackages =
            with inputs'.llm-agents.packages;
            [
              pkgs.ffmpeg-full
              pkgs.home-assistant-cli
              pkgs.mcp-nixos
              pkgs.obsidian
              self'.packages.codebase-memory-mcp
              self'.packages.cua-driver
              self'.packages.gh-axi
              rtk
            ]
            ++ config.ai.extraPackages;

          extraLibraries = [ pkgs.portaudio ];

          extraPlugins = [
            (pkgs.fetchFromGitHub {
              owner = "stephenschoettler";
              repo = "hermes-lcm";
              rev = "v0.20.0";
              hash = "sha256-yJ1Nn+su7YbKd+cgVOizXChzLbKHqTprSprF1p9/HYk=";
            })
          ];

          extraPythonPackages = [
            (
              let
                pname = "rtk-hermes";
                version = "1.2.3";
              in
              pkgs.python312Packages.buildPythonPackage {
                inherit pname version;
                src = pkgs.fetchFromGitHub {
                  owner = "ogallotti";
                  repo = pname;
                  rev = "v${version}";
                  hash = "sha256-7YRW6PODrCapfYLFn3DvgHAEME//RGC48GQt+s9ot0s=";
                };
                format = "pyproject";
                build-system = [ pkgs.python312Packages.setuptools ];
              }
            )
          ];

          extraDependencyGroups = [
            "messaging"
            "edge-tts"
            "exa"
            "honcho"
            "voice"
            "tts-premium"
          ];
        };

        home.packages = [ config.services.hermes-agent.desktopPackage ];

        home.file.".hermes/dashboard-themes/clean-webui.yaml" = {
          force = true;
          source = "${
            pkgs.fetchFromGitHub {
              owner = "fplanque";
              repo = "hermes-agent-dashboard-theme-clean";
              rev = "e7d58098f3a3ffc6866e59f4f054fa64c09913e0";
              hash = "sha256-DDBws/rdcwCaUJ2TeGIuaDR0EaDrI0qGs7LhYxHAd9A=";
            }
          }/clean-webui.yaml";
        };

        sops.secrets."hermes.env".sopsFile = ../../../../secrets/users/gabe/hermes.yaml;
      };
  };

  flake-file.inputs.hermes-agent = {
    url = "github:NousResearch/hermes-agent";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
