{
  den.aspects.workmux.homeManager =
    {
      inputs',
      lib,
      pkgs,
      ...
    }:
    let
      package = inputs'.llm-agents.packages.workmux;
      yamlFormat = pkgs.formats.yaml { };
    in
    {
      home.packages = [ package ];
      home.shellAliases.wm = lib.getExe package;

      programs.tmux.extraConfig = lib.mkAfter ''
        run-shell "${lib.getExe package} sidebar on"
      '';

      xdg.configFile."workmux/config.yaml".source = yamlFormat.generate "workmux-config.yaml" {
        agent = "pi";
        nerdfont = true;
        panes = [
          {
            command = "<agent>";
            focus = true;
          }
          { split = "horizontal"; }
        ];
      };
    };
}
