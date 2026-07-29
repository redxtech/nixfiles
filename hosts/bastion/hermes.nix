{
  config,
  pkgs,
  lib,
  ...
}:

let
  hermes = config.services.hermes-agent;
in
{
  services.hermes-agent = {
    enable = true;

    addToSystemPackages = true;

    environmentFiles = [ config.sops.secrets.hermes-env.path ];

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
          "rtk-rewrite"
        ];
      };
    };

    extraPackages = with pkgs; [
      ffmpeg
      llm-agents.rtk
    ];

    extraPlugins = [
      (pkgs.fetchFromGitHub {
        owner = "stephenschoettler";
        repo = "hermes-lcm";
        rev = "v0.19.0";
        hash = "sha256-B80HCn3BT+M1B8THMm3Ph5tpimTB68yIVkBfPaV4X40=";
      })
      # (pkgs.fetchFromGitHub {
      #   owner = "mnemosyne-oss";
      #   repo = "mnemosyne";
      #   rev = "v3.11.1";
      #   hash = "sha256-DM21ZjwCUTtyzlYn5whfIrrte5BDKVQQb5zSkOV3DlY=";
      # })
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
      (
        let
          pname = "hermes-mnemosyne";
          version = "3.11.1";
        in
        buildPythonPackage {
          inherit pname version;
          src = pkgs.fetchFromGitHub {
            owner = "mnemosyne-oss";
            repo = "mnemosyne";
            rev = "v${version}";
            hash = "sha256-DM21ZjwCUTtyzlYn5whfIrrte5BDKVQQb5zSkOV3DlY=";
          };
          root = "$REPO_ROOT/integrations/hermes";
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
      super-productivity.command = "/home/gabe/.nix-profile/bin/super-productivity-mcp";
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
      "d /var/lib/hermes/.hermes/dashboard-themes                   2770 hermes hermes - -"
      "C /var/lib/hermes/.hermes/dashboard-themes/clean-webui.yaml  0644 hermes hermes - ${clean-webui}"
    ];

  network.services.hermes = 9119;

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

  sops.secrets.hermes-env = {
    sopsFile = ./secrets.yaml;
    owner = config.services.hermes-agent.user;
    group = config.services.hermes-agent.group;
    mode = "0440";
  };
}
