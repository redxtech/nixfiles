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
            aperture.url = "https://aperture.colobus-pirate.ts.net/v1/mcp";
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
          };
        };

        # native pi needs its own config path and command-based secret references
        home.file = lib.mkIf config.programs.pi-coding-agent.enable {
          "${config.programs.pi-coding-agent.configDir}/mcp.json".source =
            (pkgs.formats.json { }).generate "pi-mcp.json"
              {
                mcpServers = lib.mapAttrs (
                  _: server:
                  lib.hm.mcp.transformMcpServer {
                    inherit server;
                    extraTransforms = [ lib.hm.mcp.addType ];
                    mkFileRef = path: "!${lib.getExe' pkgs.coreutils "cat"} ${lib.escapeShellArg path}";
                  }
                ) config.programs.mcp.servers;
              };
        };

        home.packages = [
          self'.packages.codebase-memory-mcp
          self'.packages.mcp-remote
          self'.packages.super-productivity-mcp
          self'.packages.kagi-mcp
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
