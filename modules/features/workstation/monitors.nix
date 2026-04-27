{ lib, ... }:

{
  den.aspects.monitors = {
    settings =
      let
        inherit (lib) mkOption mkEnableOption;
      in
      with lib.types;
      {
        enable = mkEnableOption "Enable monitors";

        primary = mkOption {
          description = "Primary monitor";
          type = nullOr str;
          default = null;
          readOnly = true;
        };

        monitors = mkOption {
          description = "List of all monitors";
          type = listOf (submodule {
            options = {
              name = mkOption {
                type = str;
                default = null;
              };
              enable = mkOption {
                type = bool;
                default = true;
              };
              primary = mkOption {
                type = bool;
                default = false;
              };
              height = mkOption {
                type = int;
                default = 1080;
              };
              width = mkOption {
                type = int;
                default = 1920;
              };
              rate = mkOption {
                type = float;
                default = 60.0;
              };
              vrr = mkOption {
                type = bool;
                default = false;
                description = "Enable variable refresh rate";
              };
              x = mkOption {
                type = int;
                default = 0;
              };
              y = mkOption {
                type = int;
                default = 0;
              };
              scale = mkOption {
                type = float;
                default = 1.0;
              };
              workspaces = mkOption {
                type = listOf (submodule {
                  options = {
                    number = mkOption {
                      type = int;
                      example = 1;
                      default = 1;
                    };
                    name = mkOption {
                      type = nullOr str;
                      default = null;
                      example = "home";
                    };
                  };
                });
                default = null;
                example = [
                  {
                    number = 1;
                    name = "home";
                  }
                  {
                    number = 2;
                    name = "web";
                  }
                ];
              };
            };
          });
          default = [ ];
          example = [
            {
              name = "HDMI-1";
              primary = true;
            }
          ];
        };
      };

    homeManager =
      { host, ... }:
      let
        cfg = host.settings.monitors;
        primaryMonitors = (lib.filter (m: m.primary) cfg.monitors);
      in
      lib.mkIf cfg.enable {
        # ensure exactly one monitor is set to primary
        assertions = [
          {
            assertion = ((lib.length cfg.monitors) != 0) -> ((lib.length primaryMonitors) == 1);
            message = "Exactly one monitor must be set to primary.";
          }
        ];

        services.kanshi =
          let
            mkKanshiOutput =
              {
                name,
                height,
                width,
                rate,
                vrr,
                x,
                y,
                scale,
                ...
              }:
              {
                inherit scale;
                criteria = name;
                mode = "${toString width}x${toString height}@${toString rate}";
                position = "${toString x},${toString y}";
                adaptiveSync = vrr;
              };
          in
          {
            enable = false; # TODO: re-enable when not testing in a VM

            systemdTarget = "graphical-session.target";

            settings = [
              {
                profile = {
                  name = "default";
                  outputs = map mkKanshiOutput cfg.monitors;
                };
              }
            ];
          };
      };
  };
}
