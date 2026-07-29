{
  den.aspects.opencode = {
    homeManager =
      {
        inputs',
        config,
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
            codegraph
            rtk
            inputs'.kolu.packages.default
          ];

          settings = {
            plugin = [
              # "superpowers@git+https://github.com/obra/superpowers.git"
              "background-agents@git+https://github.com/kdcokenny/opencode-background-agents.git"
              "autotitle@git+https://github.com/pawelma/opencode-autotitle.git"
              "notify@git+github.com/kdcokenny/opencode-notify.git"
            ];
          };

          skills = { };

          context = ''
            ## Environment
            You are running on a nixos system.
            Programs are available from nixpkgs if they are not already in path, via `nix run nixpkgs#<program>`.
            You can also run programs with `nix run github:<owner>/<repo>[#<program>]`, if the package is not in nixpkgs.

            ## Process Management
            New PTYs, subagents, and other background processes must be started using kolu, via the kolu MCP.

            <!-- CODEGRAPH_START -->
            ## CodeGraph

            In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

            - **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
            - **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

            If there is no `.codegraph/` directory, run `codegraph init` to initialize it.
            <!-- CODEGRAPH_END -->
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

        home.packages = [
          inputs'.llm-agents.packages.opencode2
          inputs'.llm-agents.packages.oh-my-opencode
        ];
      };
  };
}
