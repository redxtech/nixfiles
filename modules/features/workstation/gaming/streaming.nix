{ lib, ... }:

{
  # NOTE: needs to be enabled per-host
  den.aspects.streaming = {
    # TODO: make moondeck-buddy into a standard nixos module, then use that for config
    settings.moondeck = lib.mkEnableOption "Enable moondeck-buddy." // {
      default = true;
    };

    nixos =
      {
        self',
        host,
        config,
        pkgs,
        lib,
        ...
      }:
      {
        services.sunshine =
          let
            inherit (host.settings.monitors) monitors;
            primaryMonitor = (lib.head (lib.filter (m: m.primary) monitors)).name;
            monitorIndex = lib.lists.findFirstIndex (x: x.name == primaryMonitor) 0 monitors;
          in
          {
            enable = true;
            openFirewall = true;
            capSysAdmin = true;

            settings = {
              sunshine_name =
                let
                  capitalize =
                    str:
                    let
                      charsRaw = lib.splitString "" str;
                      chars = lib.tail charsRaw; # drop the empty string at the start
                      firstChar = lib.toUpper (lib.head chars);
                      restChars = lib.tail chars;
                    in
                    (firstChar + (lib.concatStrings restChars));
                in
                (capitalize config.networking.hostName);

              output_name = monitorIndex;
            };

            applications.apps = [
              {
                name = "Desktop";
                image-path = "desktop.png";
              }
              {
                name = "Steam Big Picture";
                output = "steam.txt";
                detached = [
                  "${lib.getExe' pkgs.util-linux "setsid"} ${lib.getExe pkgs.steam} steam://open/bigpicture"
                ];
                image-path = "steam.png";
              }
              (lib.mkIf (host.settings.streaming.moondeck) {
                name = "MoonDeckStream";
                command = lib.getExe' pkgs.moondeck-buddy "MoonDeckStream";
                image-path = "steam.png";
                auto-detach = "false";
                wait-all = "false";
              })
              # TODO: test this
              {
                name = "Desktop (Resized)";
                prep-cmd = [
                  {
                    do = ''
                      ${lib.getExe pkgs.bash} -c "${lib.getExe pkgs.wlr-randr} --output ${primaryMonitor} --mode \"''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}@''${SUNSHINE_CLIENT_FPS}\""
                    '';
                    undo = "${lib.getExe' pkgs.kanshi "kanshictl"} switch default";
                  }
                ];
                # exclude-global-prep-cmd = "false";
                # auto-detach = "true";
                image-path = "desktop-alt.png";
              }
            ];
          };

        systemd.user.services.moondeck-buddy = lib.mkIf host.settings.streaming.moondeck {
          unitConfig = {
            Description = "MoonDeckBuddy";
            After = [ "graphical-session.target" ];
          };
          serviceConfig = {
            ExecStart = lib.getExe self'.packages.moondeck-buddy;
            Restart = "on-failure";
          };
          wantedBy = [ "graphical-session.target" ];
        };

        environment.systemPackages = lib.optional host.settings.streaming.moondeck self'.packages.moondeck-buddy;
      };
  };
}
