{ self, ... }:

{
  den.aspects.herdr = {

    nixos =
      { host, config, ... }:
      {
        network.services.collie =
          config.home-manager.users.${host.settings.base.primaryUser}.services.collie.port;
      };

    homeManager =
      {
        self',
        inputs',
        config,
        osConfig,
        lib,
        ...
      }:
      let
        herdr = inputs'.llm-agents.packages.herdr.overrideAttrs (previous: {
          src = previous.src.override {
            owner = "redxtech";
            repo = "herdr";
            tag = null;
            rev = "7b675f42af35508eab66ac42fe1598628597a893"; # feat(detect): add muse agent with generic pick blocked detection
            hash = "sha256-hCh01iJJalF8g9pavFHIN4kFQiiCnhfwaNJ9Weevj6c=";
          };
        });
      in
      {
        imports = [ self.homeManagerModules.collie ];

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

        services.collie = {
          enable = true;
          publicHosts = [ "collie.${osConfig.networking.fqdn}" ];
          environmentFile = config.sops.secrets.collie_vapid_env.path;
        };

        sops.secrets.collie_vapid_env.path = "${config.xdg.configHome}/herdr/plugins/config/herdr.collie/.env";

        home = {
          file = {
            "${config.xdg.configHome}/systemd/user/collie.service".force = lib.mkForce true;
            "${config.xdg.configHome}/systemd/user/default.target.wants/collie.service".force =
              lib.mkForce true;
          };

          # ensure restart triggers run only after sops materializes the environment file.
          activation.collie-vapid-ready = lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "sops-nix" ] "";

          # keep herdr on the immutable plugin copy whose actions respect home manager ownership.
          activation.collie-plugin = lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "linkGeneration" ] ''
            plugins="$(${lib.getExe herdr} plugin list)"
            collie_entry=""
            while IFS= read -r line; do
              case "$line" in
                "- herdr.collie "*) collie_entry="$line"; break ;;
              esac
            done <<< "$plugins"

            expected="enabled [local:${config.services.collie.package}/lib/collie]"
            if [[ "$collie_entry" != *"$expected"* ]]; then
              if [[ "$collie_entry" == *"[github:"* ]]; then
                run ${lib.getExe herdr} plugin uninstall herdr.collie
              elif [[ "$collie_entry" == *"[local:"* ]]; then
                run ${lib.getExe herdr} plugin unlink herdr.collie
              fi

              run ${lib.getExe herdr} plugin link ${config.services.collie.package}/lib/collie --enabled
            fi
          '';

          packages = [ (self'.packages.wt-herdr.override { inherit herdr; }) ];
        };

        systemd.user.services.collie.Unit.X-Restart-Triggers = [
          "${config.sops.secrets.collie_vapid_env.sopsFile}"
        ];
      };
  };
}
