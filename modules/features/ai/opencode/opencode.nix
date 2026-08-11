{ self, ... }:

{
  den.aspects.opencode = {
    homeManager =
      {
        self',
        inputs',
        pkgs,
        ...
      }:
      {
        programs.opencode = {
          enable = true;
          enableMcpIntegration = true;

          package = inputs'.llm-agents.packages.opencode;

          extraPackages = with inputs'.llm-agents.packages; [
            apm
            rtk
            inputs'.kolu.packages.default
            pkgs.python3

            # lsps
            pkgs.bash-language-server
            pkgs.emmylua-ls
            pkgs.luaPackages.lua-lsp
            pkgs.nixd
            pkgs.pyright
            pkgs.yaml-language-server
          ];

          settings = {
            autoupdate = false;
            formatter = true;
            lsp = true;

            plugin = [
              "background-agents@git+https://github.com/kdcokenny/opencode-background-agents.git"
              "notify@git+github.com/kdcokenny/opencode-notify.git"
              "@tarquinen/opencode-smart-title"
            ];
          };

          context = ''
            ## Environment
            You are running on a nixos system.
            Programs are available from nixpkgs if they are not already in path, via `nix run nixpkgs#<program>`.
            You can also run programs with `nix run github:<owner>/<repo>[#<program>]`, if the package is not in nixpkgs.

            ## Process Management
            New PTYs, subagents, and other background processes must be started using kolu, via the kolu MCP.
          '';
        };

        xdg.configFile."opencode/plugins/rtk.ts".source =
          let
            version = "0.44.1";
            rtk = pkgs.fetchFromGitHub {
              owner = "rtk-ai";
              repo = "rtk";
              rev = "v${version}";
              hash = "sha256-5AN/sK0IOIqcLX0FviFPOJ9QX9xJpliSN1XY3isxyrA=";
            };
          in
          "${rtk}/hooks/opencode/rtk.ts";

        home.packages = [ inputs'.llm-agents.packages.opencode2 ];
      };
  };
}
