{ den, ... }:

{
  den.aspects.ai = {
    includes = [
      den.aspects.herdr
      den.aspects.mcp
      den.aspects.workmux
    ];

    homeManager =
      {
        self',
        inputs',
        pkgs,
        ...
      }:
      let
        llmAgentsPackages = inputs'.llm-agents.packages;
        selfPackages = self'.packages;
      in
      {
        programs.pi-coding-agent = {
          enable = true;
          # pi-lcm uses better-sqlite3, which is unsupported by pi's bun runtime.
          package = inputs'.llm-agents.packages.pi.override { useBun = false; };
          extraPackages = [
            pkgs.defuddle
            pkgs.gcc
            pkgs.gnumake
            pkgs.jq
            pkgs.python3
          ]
          ++ [ llmAgentsPackages.rtk ]
          ++ [
            selfPackages.cyber-mux
            selfPackages.docker-axi
            selfPackages.gh-axi
            selfPackages.gws-axi
            selfPackages.kagi-mcp
            selfPackages.karakeep-cli
            selfPackages.kubernetes-axi
            selfPackages.mcp-remote
            selfPackages.strava-mcp
            selfPackages.super-productivity-mcp
            selfPackages.workspace-mcp
          ];

        };

        programs.codex.enable = true;
        programs.codex.package = llmAgentsPackages.codex;

        home.packages = [
          # general tools
          llmAgentsPackages.apm # agent package manager
          llmAgentsPackages.aven # powerful todo manager
          # beads # agent-first issue tracker
          llmAgentsPackages.but # cli for gitbutler
          llmAgentsPackages.ccusage # token usage
          llmAgentsPackages.gitbutler # git client
          llmAgentsPackages.hunk # review-first diff viewer
          llmAgentsPackages.openspec # spec-driven development
          llmAgentsPackages.prime-agent # RLM agent
          llmAgentsPackages.rtk # token consumption optimization
          llmAgentsPackages.skills # vercel skills installer
          llmAgentsPackages.tuicr # code revivew tool

          pkgs.bun # a lot of tools use bun
          # pkgs.dolt # git for data
        ];
      };
  };

  flake-file.inputs.llm-agents.url = "github:numtide/llm-agents.nix";

  flake-file.nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };
}
