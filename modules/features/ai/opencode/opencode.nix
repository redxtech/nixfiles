{
  den.aspects.opencode = {
    homeManager =
      {
        self',
        inputs',
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # TODO: add all skills from juspay/kolu/agents
        # TODO: add hm module that abstracts agents and skills, and adds them to opencode, codex, and claude-code

        agency = pkgs.fetchFromGitHub {
          owner = "srid";
          repo = "agency";
          rev = "f360f59a2634da2e83772d37b356bc4fd86c9d50"; # master
          hash = "sha256-7F0F55lH057UWZ/DYDUkHKT8m+MImgItGn3QtuMD8ws=";
        };

        aiSlopCure = pkgs.fetchFromGitHub {
          owner = "woosal1337";
          repo = "blog";
          rev = "b912d5fa59f368253683af2ebfac64ad6d08312d";
          hash = "sha256-Cm/DOQL1l3ntRg93psJlD4wUwVroSOuv6t6R3CFpUAg=";
        };

        # the hickey/lowy agents delegate to the skills of the same name;
        # fact-check is a hard dependency of every review skill
        agencySkills = [
          "code-police"
          "elegance"
          "fact-check"
          "forge-pr"
          "hickey"
          "lowy"
          "talk"
        ];
      in
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
            pkgs.python3
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

          # structural review lenses, delegate to the hickey/lowy skills
          agents = {
            hickey = agency + "/.apm/agents/hickey.md";
            lowy = agency + "/.apm/agents/lowy.md";
            technical-writer = ./agents/technical-writer.md;
          };

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

        home.file =
          lib.listToAttrs (
            map (
              name: lib.nameValuePair ".agents/skills/${name}" { source = agency + "/.apm/skills/${name}"; }
            ) agencySkills
          )
          // {
            ".agents/skills/ste-writing/SKILL.md".source =
              aiSlopCure + "/videos/ep01-the-cure-for-ai-slop/ste-writing-skill.md";
            ".agents/skills/ste-writing/scripts/ste-lint.py".source =
              aiSlopCure + "/videos/ep01-the-cure-for-ai-slop/ste-lint.py";
          };

        home.packages = [
          inputs'.llm-agents.packages.opencode2
          inputs'.llm-agents.packages.oh-my-opencode
          self'.packages.openportal
        ];
      };
  };
}
