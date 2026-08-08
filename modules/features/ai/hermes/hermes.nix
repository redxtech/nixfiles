{ lib, self, ... }:

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
        ...
      }:
      {
        imports = [ self.homeManagerModules.hermes ];

        services.hermes-agent = {
          enable = true;
          dashboard.enable = true;

          environmentFiles = [ config.sops.secrets."hermes.env".path ];
          environment.CUA_DRIVER_RS_ENABLE_WAYLAND = "1";

          settings = {
            model.provider = "openai-codex";
            model.default = "gpt-5.6-sol";

            dashboard.theme = "clean-webui";
            dashboard.show_token_analytics = true;

            context.engine = "lcm";
            memory.provider = "honcho";

            session_reset = {
              mode = "idle";
              idle_minutes = 15;
              notify = false;
            };

            toolsets = [ "all" ];

            terminal.backend = "local";

            tts.provider = "elevenlabs";
            tts.elevenlabs.voice_id = "CwhRBWXzGAHq8TQ4Fs17";
            # tts.elevenlabs.voice_id = "LruHrtVF6PSyGItzMNHS"; # TODO: use when not on free tier

            display = {
              show_reasoning = true;
              streaming = true;
              show_cost = true;
              timestamps = true;
            };

            approvals.mode = "smart";

            plugins.enabled = [
              "hermes-lcm"
              "rtk-rewrite"
            ];
          };

          extraPackages = with inputs'.llm-agents.packages; [
            pkgs.ffmpeg-full
            rtk
          ];

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

          # TODO: pull from config.mcp
          mcpServers = {
            nixos.command = lib.getExe pkgs.mcp-nixos;
            super-productivity.command = lib.getExe self'.packages.super-productivity-mcp;
            kolu = {
              command = lib.getExe inputs'.kolu.packages.default;
              args = [ "mcp" ];
            };
            kagi = {
              url = "https://mcp.kagi.com/mcp";
              headers.Authorization = "Bearer \${MCP_KAGI_KEY}";
              timeout = 180;
            };
            github = {
              url = "https://api.githubcopilot.com/mcp";
              headers.Authorization = "Bearer \${MCP_GITHUB_KEY}";
              timeout = 180;
            };
            liftosaur = {
              url = "https://www.liftosaur.com/mcp";
              headers.Authorization = "Bearer \${MCP_LIFTOSAUR_KEY}";
              timeout = 180;
            };
            strava.command = lib.getExe self'.packages.strava-mcp;
            homeassistant = {
              url = "https://ha.mothership.sucha.foo/api/mcp";
              headers.Authorization = "Bearer \${MCP_HOMEASSISTANT_KEY}";
              timeout = 180;
            };
            obsidian = {
              url = "http://localhost:27123/mcp/";
              headers.Authorization = "Bearer \${MCP_OBSIDIAN_KEY}";
              timeout = 180;
            };
          };
        };

        home.packages = [
          inputs'.hermes-agent.packages.desktop
          self'.packages.cua-driver
        ];

        home.file.".hermes/dashboard-themes/clean-webui.yaml".source = "${
          pkgs.fetchFromGitHub {
            owner = "fplanque";
            repo = "hermes-agent-dashboard-theme-clean";
            rev = "e7d58098f3a3ffc6866e59f4f054fa64c09913e0";
            hash = "sha256-DDBws/rdcwCaUJ2TeGIuaDR0EaDrI0qGs7LhYxHAd9A=";
          }
        }/clean-webui.yaml";

        sops.secrets."hermes.env".sopsFile = ../../../../secrets/users/gabe/hermes.yaml;
      };
  };

  flake-file.inputs.hermes-agent = {
    url = "github:NousResearch/hermes-agent";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
