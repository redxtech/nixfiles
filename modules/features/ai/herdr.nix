{ self, ... }:

{
  den.aspects.herdr = {
    homeManager =
      {
        self',
        inputs',
        lib,
        ...
      }:
      let
        herdr = inputs'.llm-agents.packages.herdr.overrideAttrs (previous: {
          src = previous.src.override {
            owner = "redxtech";
            repo = "herdr";
            tag = null;
            rev = "117eebd15290dd0bb7c78ca884732c5e2983992e"; # feat: port herdr:busy to omp
            hash = "sha256-J7MyMspBOnwkGTwvUEF38FaVf/a3cjy667wCQNJP5CE=";
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
              tab_bar_right_separator = " · ";
              tab_bar_right = [
                { type = "zoom"; }
                { type = "hostname"; }
                {
                  type = "datetime";
                  format = "%H:%M";
                }
              ];
              sidebar = {
                spaces = {
                  rows = [
                    [
                      "state_icon"
                      "workspace"
                    ]
                    [
                      "branch"
                      "git_status"
                    ]
                  ];
                };
                agents = {
                  rows = [
                    [
                      "state_icon"
                      "workspace"
                      "tab"
                    ]
                    [
                      "agent"
                      "state_text"
                    ]
                  ];
                };
              };
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
