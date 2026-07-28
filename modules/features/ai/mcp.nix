{
  den.aspects.mcp = {
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
        programs.mcp = {
          enable = true;

          # servers to consider adding:
          # - superpowers (https://github.com/obra/superpowers)
          # - worldmonitor (https://github.com/koala73/worldmonitor)
          # - context7 (https://github.com/upstash/context7)
          # - strava (https://support.strava.com/en-us/articles/15401531-strava-mcp-connector)
          # - thunderbird (https://github.com/TKasperczyk/thunderbird-mcp)

          servers = {
            nixos.command = lib.getExe pkgs.mcp-nixos;
            super-productivity.command = lib.getExe self'.packages.super-productivity-mcp;
            codegraph = {
              command = lib.getExe inputs'.llm-agents.packages.codegraph;
              args = [
                "serve"
                "--mcp"
              ];
            };
            kolu = {
              command = lib.getExe inputs'.kolu.packages.default;
              args = [ "mcp" ];
            };
            liftosaur = {
              enable = false; # don't auto-configure this in supported editors
              command = lib.getExe self'.packages.mcp-remote;
              args = [
                "https://www.liftosaur.com/mcp"
                "--header"
                "Authorization:Bearer \${MCP_LIFTOSAUR_KEY}"
              ];
              env.MCP_LIFTOSAUR_KEY.file = config.sops.secrets.mcp-liftosaur-key.path;
            };
            homeassistant = {
              enable = false; # don't auto-configure this in supported editors
              command = lib.getExe self'.packages.mcp-remote;
              args = [
                "https://ha.mothership.sucha.foo/api/mcp"
                "--header"
                "Authorization:Bearer \${MCP_HOMEASSISTANT_KEY}"
              ];
              env.MCP_HOMEASSISTANT_KEY.file = config.sops.secrets.mcp-homeassistant-key.path;
            };
            github = {
              command = lib.getExe self'.packages.mcp-remote;
              args = [
                "https://api.githubcopilot.com/mcp/"
                "--header"
                "Authorization:Bearer \${MCP_GITHUB_KEY}"
              ];
              env.MCP_GITHUB_KEY.file = config.sops.secrets.mcp-github-key.path;
            };
            obsidian = {
              command = lib.getExe self'.packages.mcp-remote;
              args = [
                "http://localhost:27123/mcp"
                "--header"
                "Authorization:Bearer \${MCP_OBSIDIAN_KEY}"
              ];
              env.MCP_OBSIDIAN_KEY.file = config.sops.secrets.mcp-obsidian-key.path;
            };
            kagi = {
              command = lib.getExe self'.packages.kagi-mcp;
              env.KAGI_API_KEY.file = config.sops.secrets.mcp-kagi-key.path;
            };
          };
        };

        sops.secrets =
          let
            sopsFile = ../../../secrets/users/gabe/secrets.yaml;
          in
          {
            mcp-homeassistant-key.sopsFile = sopsFile;
            mcp-liftosaur-key.sopsFile = sopsFile;
            mcp-github-key.sopsFile = sopsFile;
            mcp-obsidian-key.sopsFile = sopsFile;
            mcp-kagi-key.sopsFile = sopsFile;
          };
      };
  };
}
