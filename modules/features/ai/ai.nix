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

        cfg = config.ai;
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

        codexProfile = tomlFormat.generate "nix.config.toml" {
          agents = codexAgents;
        };

        codex = pkgs.writeShellScriptBin "codex" ''
          exec ${lib.getExe codexPackage} --profile nix "$@"
        '';
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
              // {
                ste-writing = pkgs.linkFarm "ste-writing-skill" [
                  {
                    name = "SKILL.md";
                    path = aiSlopCure + "/videos/ep01-the-cure-for-ai-slop/ste-writing-skill.md";
                  }
                  {
                    name = "scripts/ste-lint.py";
                    path = aiSlopCure + "/videos/ep01-the-cure-for-ai-slop/ste-lint.py";
                  }
                ];
              };

            home.packages = with inputs'.llm-agents.packages; [
              # agents
              claude-code
              claude-agent-acp

              codex
              codex-acp

              # orchestrators
              # herdr

              # general tools
              apm # agent package manager
              ccusage # token usage
              codegraph # code indexing and search
              openskills # skills installer
              rtk # token consumption optimization
            ];

            home.file =
              lib.mapAttrs' (
                name: source: lib.nameValuePair ".agents/skills/${name}" { inherit source; }
              ) cfg.skills
              // lib.mapAttrs' (
                name: source: lib.nameValuePair ".codex/skills/${name}" { inherit source; }
              ) cfg.skills
              // {
                ".codex/nix.config.toml".source = codexProfile;
              };
          }

          (lib.mkIf config.programs.opencode.enable {
            programs.opencode = {
              agents = cfg.agents;
              skills = cfg.skills;
            };
          })

          (lib.mkIf config.programs.claude-code.enable {
            programs.claude-code = {
              agents = cfg.agents;
              skills = cfg.skills;
            };
          })
        ];
      };
  };

  flake-file.inputs.llm-agents.url = "github:numtide/llm-agents.nix";

  flake-file.nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };
}
