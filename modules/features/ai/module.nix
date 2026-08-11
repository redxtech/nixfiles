{
  flake.homeManagerModules.ai =
    {
      config,
      inputs',
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.ai;

      contextText = lib.concatMapStringsSep "\n\n" (
        source: if builtins.isPath source then builtins.readFile source else source
      ) cfg.context;
      contextFile = pkgs.writeText "AGENTS.md" contextText;

      formatSkill =
        name: source:
        pkgs.runCommand "formatted-agent-skill-${name}"
          {
            nativeBuildInputs = [
              pkgs.perl
              pkgs.yq-go
            ];
          }
          ''
            cp -RL ${source} "$out"
            chmod -R u+w "$out"
            perl -i -pe '
              if ($. == 1 && /^---\s*$/) {
                $in_frontmatter = 1;
              } elsif ($in_frontmatter && /^---\s*$/) {
                $in_frontmatter = 0;
              } elsif ($in_frontmatter && /^description:\s*(.*)$/) {
                $description = $1;
                unless ($description =~ /^"/ || substr($description, 0, 1) eq chr 39 || $description =~ /^[>|][+-]?$/) {
                  $description =~ s/\\/\\\\/g;
                  $description =~ s/"/\\"/g;
                  $_ = "description: \"$description\"\n";
                }
              }
            ' "$out/SKILL.md"
            yq --front-matter=process -i '.description style="double"' "$out/SKILL.md"
          '';

      finalSkills = lib.mapAttrs formatSkill cfg.skills;
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

        finalSkills = lib.mkOption {
          type = lib.types.attrsOf lib.types.path;
          readOnly = true;
          description = "Formatted skill directories shared by supported coding agents";
        };

        context = lib.mkOption {
          type = lib.types.listOf (lib.types.either lib.types.lines lib.types.path);
          default = [ ];
          description = ''
            Global agent context. Strings and file contents are concatenated in order,
            separated by blank lines, and installed as AGENTS.md for supported agents.
          '';
          example = lib.literalExpression ''
            [
              ./agents/AGENTS.md
              "Additional global instructions"
            ]
          '';
        };

        contextFile = lib.mkOption {
          type = lib.types.path;
          readOnly = true;
          description = "Generated AGENTS.md containing the combined global agent context";
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
          ai = { inherit contextFile finalSkills; };

          # TODO: remove when packages are automatically injected into all the harnesses
          home.packages = cfg.extraPackages;

          home.file =
            lib.mapAttrs' (
              name: source: lib.nameValuePair ".agents/skills/${name}" { inherit source; }
            ) finalSkills
            // lib.optionalAttrs (cfg.context != [ ]) {
              ".agents/AGENTS.md".source = contextFile;
            };
        }

        (lib.mkIf config.programs.opencode.enable {
          programs.opencode = {
            inherit (cfg) agents skills extraPackages;
          }
          // lib.optionalAttrs (cfg.context != [ ]) {
            context = lib.mkBefore contextText;
          };
        })

        (lib.mkIf config.programs.claude-code.enable {
          programs.claude-code = {
            inherit (cfg) agents skills;
          }
          // lib.optionalAttrs (cfg.context != [ ]) {
            context = lib.mkBefore contextText;
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
              inherit (cfg) skills;
              profiles.nix.agents = codexAgents;
            }
            // lib.optionalAttrs (cfg.context != [ ]) {
              context = lib.mkBefore contextText;
            };

            home.packages = [ inputs'.llm-agents.packages.codex-acp ];
          }
        ))

        (lib.mkIf (config.programs.pi-coding-agent.enable && cfg.context != [ ]) {
          programs.pi-coding-agent.context = lib.mkBefore contextText;
        })
      ];
    };
}
