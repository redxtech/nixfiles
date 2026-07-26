{
  den.aspects.mcp = {
    homeManager =
      {
        self',
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
            liftosaur = {
              enable = false; # don't auto-configure this in supported editors
              command = lib.getExe self'.packages.mcp-remote;
              args = [
                "https://www.liftosaur.com/mcp"
                "--header"
                "Authorization:Bearer {env:MCP_LIFTOSAUR_KEY}"
              ];
              env.MCP_LIFTOSAUR_KEY.file = config.sops.secrets.mcp-liftosaur-key.path;
            };
            homeassistant = {
              enable = false; # don't auto-configure this in supported editors
              command = lib.getExe self'.packages.mcp-remote;
              args = [
                "https://ha.mothership.sucha.foo/api/mcp"
                "--header"
                "Authorization:Bearer {env:MCP_HOMEASSISTANT_KEY}"
              ];
              env.MCP_HOMEASSISTANT_KEY.file = config.sops.secrets.mcp-homeassistant-key.path;
            };
            github = {
              command = lib.getExe self'.packages.mcp-remote;
              args = [
                "https://api.githubcopilot.com/mcp"
                "--header"
                "Authorization:Bearer {env:MCP_GITHUB_KEY}"
              ];
              env.MCP_GITHUB_KEY.file = config.sops.secrets.mcp-github-key.path;
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
          };
      };
  };
}
