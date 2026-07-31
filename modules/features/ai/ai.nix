{ den, ... }:

{
  den.aspects.ai = {
    includes = [
      den.aspects.kolu
      den.aspects.mcp
      den.aspects.opencode
    ];

    homeManager =
      {
        self',
        config,
        inputs',
        lib,
        pkgs,
        ...
      }:
      let
        agency = pkgs.fetchFromGitHub {
          owner = "srid";
          repo = "agency";
          rev = "f360f59a2634da2e83772d37b356bc4fd86c9d50"; # master
          hash = "sha256-7F0F55lH057UWZ/DYDUkHKT8m+MImgItGn3QtuMD8ws=";
        };

        koluAgents = pkgs.fetchFromGitHub {
          owner = "juspay";
          repo = "kolu";
          rev = "5ec6ad09b61259be54441ec9ff7109600156a6a1"; # master
          hash = "sha256-dpQbZn5RG5JGy5g9oYkXigOyr1WXMjtYp2P9Ff+ivbo=";
        };

        mattPocock = pkgs.fetchFromGitHub {
          owner = "mattpocock";
          repo = "skills";
          rev = "2ab958093e83e0ec752e6c1c5932da465bf23e0c"; # main
          hash = "sha256-dQtG6usJWlg/FqTajrjcs8GSdymH92WsgLiUaCfvKPA=";
        };

        aiSlopCure = pkgs.fetchFromGitHub {
          owner = "woosal1337";
          repo = "blog";
          rev = "b912d5fa59f368253683af2ebfac64ad6d08312d";
          hash = "sha256-Cm/DOQL1l3ntRg93psJlD4wUwVroSOuv6t6R3CFpUAg=";
        };

        aiSlopCureLint = pkgs.writers.writePython3Bin "ste-lint" { doCheck = false; } (
          builtins.readFile (aiSlopCure + "/videos/ep01-the-cure-for-ai-slop/ste-lint.py")
        );

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

        koluAgentsSkills = [
          "agent-debate"
          "architecture-first-principles"
          "be"
          "be-review"
          "bridge"
          "coordinator"
          "diataxis"
          "hostility-review"
          "kolu"
          "lens-debate"
          "perfection-review"
          "surface"
        ];

        mattPocockSkills = [
          "engineering/ask-matt"
          "engineering/diagnosing-bugs"
          "engineering/grill-with-docs"
          "engineering/triage"
          "engineering/improve-codebase-architecture"
          "engineering/setup-matt-pocock-skills"
          "engineering/tdd"
          "engineering/to-spec"
          "engineering/to-tickets"
          "engineering/wayfinder"
          "engineering/implement"
          "engineering/prototype"
          "engineering/research"
          "engineering/domain-modeling"
          "engineering/codebase-design"
          "engineering/code-review"
          "engineering/resolving-merge-conflicts"
          "productivity/grill-me"
          "productivity/grilling"
          "productivity/handoff"
          "productivity/teach"
          "productivity/writing-great-skills"
        ];

        cfg = config.ai;
      in
      {
        options.ai = {
          agents = lib.mkOption {
            type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
            default = { };
            description = "Agent definitions shared by supported coding agents";
          };

          skills = lib.mkOption {
            type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
            default = { };
            description = "Skill definitions shared by supported coding agents";
          };

          # TODO: add support for codex & claude-code
          extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = [ ];
            description = "Extra packages to install for the agents";
          };
        };

        config = lib.mkMerge [
          {
            ai.agents = {
              hickey = agency + "/.apm/agents/hickey.md";
              lowy = agency + "/.apm/agents/lowy.md";
              technical-writer = ./opencode/agents/technical-writer.md;
            };

            ai.skills =
              builtins.listToAttrs (
                map (name: {
                  inherit name;
                  value = agency + "/.apm/skills/${name}";
                }) agencySkills
              )
              // builtins.listToAttrs (
                map (name: {
                  inherit name;
                  value = koluAgents + "/agents/.apm/skills/${name}";
                }) koluAgentsSkills
              )
              // builtins.listToAttrs (
                map (path: {
                  name = builtins.baseNameOf path;
                  value = mattPocock + "/skills/${path}";
                }) mattPocockSkills
              )
              // {
                ste-writing = pkgs.linkFarm "ste-writing-skill" [
                  {
                    name = "SKILL.md";
                    path = aiSlopCure + "/videos/ep01-the-cure-for-ai-slop/ste-writing-skill.md";
                  }
                  {
                    name = "scripts/ste-lint.py";
                    path = pkgs.writeShellScript "ste-lint.py" ''
                      exec ${lib.getExe aiSlopCureLint} "$@"
                    '';
                  }
                ];
              };

            ai.extraPackages = [
              inputs'.kolu.packages.default
            ]
            ++ (with inputs'.llm-agents.packages; [
              apm
              codegraph
              rtk
            ])
            ++ (with self'.packages; [
              kagi-mcp
              mcp-remote
              openportal
              super-productivity-mcp
              workspace-mcp
            ]);

            programs.codex.enable = true;

            home.packages =
              with inputs'.llm-agents.packages;
              [
                # general tools
                apm # agent package manager
                ccusage # token usage
                codegraph # code indexing and search
                openskills # skills installer
                rtk # token consumption optimization
              ]
              # TODO: remove when packages are automatically injected into all the harnesses
              ++ cfg.extraPackages;

            home.file = lib.mapAttrs' (
              name: source: lib.nameValuePair ".agents/skills/${name}" { inherit source; }
            ) cfg.skills;
          }

          (lib.mkIf config.programs.opencode.enable {
            programs.opencode = {
              agents = cfg.agents;
              skills = cfg.skills;

              extraPackages = cfg.extraPackages;
            };
          })

          (lib.mkIf config.programs.claude-code.enable {
            programs.claude-code = {
              agents = cfg.agents;
              skills = cfg.skills;
            };

            home.packages = [ inputs'.llm-agents.packages.claude-agent-acp ];
          })

          (lib.mkIf config.programs.codex.enable (
            let
              tomlFormat = pkgs.formats.toml { };
              codexPackage = inputs'.llm-agents.packages.codex;

              agentText =
                source:
                if builtins.isPath source || lib.hasPrefix "/" source then builtins.readFile source else source;

              codexAgents = lib.mapAttrs (name: source: {
                description = "${name} agent";
                config_file = tomlFormat.generate "codex-agent-${name}.toml" {
                  # TODO: Parse or strip harness-specific frontmatter before sharing agent prompts across harnesses.
                  developer_instructions = agentText source;
                };
              }) cfg.agents;

              codex = pkgs.writeShellScriptBin "codex" ''
                exec ${lib.getExe codexPackage} --profile nix "$@"
              '';
            in
            {
              programs.codex = {
                package = codex;
                skills = cfg.skills;
                profiles.nix.agents = codexAgents;
              };

              home.packages = [ inputs'.llm-agents.packages.codex-acp ];
            }
          ))
        ];
      };
  };

  flake-file.inputs.llm-agents.url = "github:numtide/llm-agents.nix";

  flake-file.nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };
}
