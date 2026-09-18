{
  den.aspects.herdr.homeManager = { self', ... }: {
    programs.herdr = {
      enable = true;
      package = self'.packages.herdr;

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

    home.packages = [
      (self'.packages.wt-herdr.override { herdr = self'.packages.herdr; })
    ];
  };
}
