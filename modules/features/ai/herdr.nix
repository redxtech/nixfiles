{
  den.aspects.herdr = {
    homeManager = { inputs', self', ... }: {
      programs.herdr = {
        enable = true;
        package = inputs'.llm-agents.packages.herdr;

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
          };
          keys = {
            prefix = "ctrl+a";
            detach = "prefix+d";
            split_vertical = "prefix+\\";
          };
        };
      };

      home.packages = [ self'.packages.wt-herdr ];
    };
  };
}
