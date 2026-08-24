{
  den.aspects.ai-skills.homeManager =
    { lib, pkgs, ... }:
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

      obsidianSkills = pkgs.fetchFromGitHub {
        owner = "kepano";
        repo = "obsidian-skills";
        rev = "a1dc48e68138490d522c04cbf5822214c6eb1202"; # main
        hash = "sha256-/Kr3cMaN81WXFxgWMNt/QQhEMzuu3e3WJpspqjrnPss=";
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

      localSkill =
        name:
        pkgs.linkFarm "${name}-skill" [
          {
            name = "SKILL.md";
            path = ./skills/${name}.md;
          }
        ];

      # the hickey/lowy agents delegate to the skills of the same name;
      # fact-check is a hard dependency of every review skill
      agencySkills = [
        "code-police"
        "elegance"
        "fact-check"
        "hickey"
        "lowy"
      ];

      koluAgentsSkills = [
        "diataxis"
        # "lens-debate"
        "perfection-review"
      ];

      mattPocockSkills = [
        "engineering/diagnosing-bugs"
        # "engineering/wayfinder"
        "engineering/research"
        "engineering/codebase-design"
        "engineering/code-review"
        "productivity/grilling"
      ];

      obsidianSkillNames = [
        "defuddle"
        "json-canvas"
        "obsidian-bases"
        "obsidian-cli"
        "obsidian-markdown"
      ];
    in
    {
      ai = {
        agents = {
          hickey = {
            source = agency + "/.apm/agents/hickey.md";
            frontmatter = {
              auto-exit = true;
              model = "openai-codex/gpt-5.6-terra";
            };
          };
          lowy = {
            source = agency + "/.apm/agents/lowy.md";
            frontmatter = {
              auto-exit = true;
              model = "openai-codex/gpt-5.6-terra";
            };
          };
        };

        skills =
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
          // builtins.listToAttrs (
            map (name: {
              inherit name;
              value = obsidianSkills + "/skills/${name}";
            }) obsidianSkillNames
          )
          // {
            cyber-mux = localSkill "cyber-mux";
            home-assistant-cli = localSkill "home-assistant-cli";

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
      };

      home.file = builtins.listToAttrs (
        map (name: {
          name = ".agents/skills/${name}";
          value.force = true;
        }) obsidianSkillNames
      );
    };
}
