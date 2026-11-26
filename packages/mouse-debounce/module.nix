{ self, ... }:

{
  flake.nixosModules.mouse-debounce =
    {
      config,
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      cfg = config.services.mouse-debounce;
      device = "/dev/input/mouse-debounce";
      deviceUnit = "${utils.escapeSystemdPath device}.device";
      duration = lib.types.ints.between 1 1000;
      toml = pkgs.formats.toml { };
      settingsFile = toml.generate "mouse-debounce.toml" (cfg.settings // { inherit device; });
      isButtonCode =
        name:
        builtins.match "[1-9][0-9]{2}" name != null
        && (
          let
            code = lib.toInt name;
          in
          code >= 256 && code <= 767
        );
    in
    {
      options.services.mouse-debounce = {
        enable = lib.mkEnableOption "mouse button debounce";

        package = lib.mkOption {
          type = lib.types.package;
          default = self.packages.${pkgs.stdenv.hostPlatform.system}.mouse-debounce;
          defaultText = lib.literalExpression "inputs.nixfiles.packages.\${pkgs.stdenv.hostPlatform.system}.mouse-debounce";
          description = "The mouse-debounce package to use.";
        };

        devicePhys = lib.mkOption {
          type = lib.types.strMatching "[[:alnum:]_.:/-]+";
          example = "keymasq/passthrough/046d:4085/if02_mouse";
          description = "Exact Linux input physical path of the mouse event device to filter.";
        };

        verbose = lib.mkEnableOption "verbose debounce logging";

        settings = {
          ms = lib.mkOption {
            type = duration;
            default = 40;
            description = "Debounce window in milliseconds when no per-button settings are set.";
          };

          buttons = lib.mkOption {
            type = lib.types.attrsOf duration;
            default = { };
            example = {
              "273" = 50;
            };
            description = ''
              Debounce windows in milliseconds by decimal evdev button code.
              If this set is not empty, other buttons pass through unchanged.
            '';
          };

          absolute_axes = lib.mkEnableOption "forwarding of absolute X and Y axes";
        };
      };

      config = lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = lib.all isButtonCode (builtins.attrNames cfg.settings.buttons);
            message = "services.mouse-debounce.settings.buttons requires decimal evdev button codes from 256 to 767.";
          }
        ];

        hardware.uinput.enable = true;

        services.udev.extraRules = ''
          SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_MOUSE}=="1", ATTRS{phys}=="${cfg.devicePhys}", SYMLINK+="${lib.removePrefix "/dev/" device}", TAG+="systemd", ENV{SYSTEMD_ALIAS}+="${device}", ENV{SYSTEMD_WANTS}+="mouse-debounce.service"
        '';

        systemd.services.mouse-debounce = {
          description = "Mouse button debounce";
          after = [ deviceUnit ];
          bindsTo = [ deviceUnit ];
          environment.XDG_RUNTIME_DIR = "/run/mouse-debounce";
          serviceConfig = {
            ExecStart =
              "${lib.getExe cfg.package} --config ${settingsFile}" + lib.optionalString cfg.verbose " --verbose";
            DynamicUser = true;
            SupplementaryGroups = [
              "input"
              "uinput"
            ];
            DevicePolicy = "closed";
            DeviceAllow = [
              "${device} r"
              "/dev/uinput rw"
            ];
            RuntimeDirectory = "mouse-debounce";
            RuntimeDirectoryMode = "0700";
            Restart = "on-failure";
          };
        };
      };
    };
}
