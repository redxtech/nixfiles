{
  den.aspects.herdr = {
    homeManager =
      { inputs', self', ... }:
      let
        herdr = inputs'.llm-agents.packages.herdr.overrideAttrs (previous: {
          src = previous.src.override {
            owner = "redxtech";
            repo = "herdr";
            tag = null;
            rev = "f46268cac60ac547538ae4245c0f7186004926dc"; # fix/pi-subagent-busy-state
            hash = "sha256-4YVObklERytkMYf6HrtosFRNQUVjC4Ph3LPkwQvT53k=";
          };
        });
      in
      {
        programs.herdr = {
          enable = true;
          package = herdr;

          settings = {
            onboarding = false;
            theme = {
              name = "dracula";
              auto_switch = false;
            };
            ui = {
              show_agent_labels_on_pane_borders = true;
              toast.delivery = "system";
              agent_panel_sort = "priority";
              status_indicators = "symbols";
            };
            keys = {
              prefix = "ctrl+a";
              detach = "prefix+d";
              split_vertical = "prefix+\\";
            };
          };
        };

        home.packages = [ (self'.packages.wt-herdr.override { inherit herdr; }) ];
      };
  };
}
