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
          # - context7 (https://github.com/upstash/context7)
          # - strava (https://support.strava.com/en-us/articles/15401531-strava-mcp-connector) - when released
          # - thunderbird (https://github.com/TKasperczyk/thunderbird-mcp)

          servers = {
            codebase-memory.command = lib.getExe self'.packages.codebase-memory-mcp;
            nixos.command = lib.getExe pkgs.mcp-nixos;
            super-productivity.command = lib.getExe self'.packages.super-productivity-mcp;
            github = {
              command = lib.getExe self'.packages.mcp-remote;
              args = [
                "https://api.githubcopilot.com/mcp/"
                "--header"
                "Authorization:Bearer \${MCP_GITHUB_KEY}"
              ];
              env.MCP_GITHUB_KEY.file = config.sops.secrets.mcp-github-key.path;
            };
            vaulted = {
              enabled = false;
              command = lib.getExe self'.packages.vaulted;
              args = [ "mcp" ];
            };
          };
        };

        home.packages = [
          self'.packages.codebase-memory-mcp
          self'.packages.mcp-remote
          self'.packages.super-productivity-mcp
          self'.packages.kagi-mcp
          self'.packages.vaulted
        ];

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
