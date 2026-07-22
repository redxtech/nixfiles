{ den, ... }:

{
  den.aspects.ai = {
    includes = [
      den.aspects.hermes
      den.aspects.kolu
      den.aspects.mcp
    ];

    homeManager =
      { inputs', ... }:
      {
        home.packages = with inputs'.llm-agents.packages; [
          # agents
          claude-code
          claude-agent-acp
          codex
          codex-acp

          kimi-code

          opencode
          oh-my-opencode

          # orchestrators
          # herdr

          # general tools
          apm # agent package manager
          ccusage # token usage
          codegraph # code indexing and search
          openskills # skills installer
          rtk # token consumption optimization
        ];
      };
  };

  flake-file.inputs.llm-agents.url = "github:numtide/llm-agents.nix";

  flake-file.nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };
}
