{ inputs, ... }:

{
  den.aspects.discord.homeManager =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      imports = [ inputs.nixcord.homeModules.nixcord ];

      programs.nixcord = {
        enable = true;
        discord.enable = false; # don't use official discord client

        # native equicord client
        equibop = {
          enable = true;
          settings = {
            discordBranch = "stable";
            tray = true;
            minimizeToTray = true;
            arRPC = true;
            trayColor = "";
            trayMainOverride = false;
            splashColor = "rgb(239, 239, 241)";
          };
        };

        # lightweight client
        legcord = {
          enable = true;
          equicord.enable = true;
          vencord.enable = false;

          settings = {
            hardwareAcceleration = true;
            minimizeToTray = true;
            tray = "dynamic";
          };
        };
      };

      # disable generating settings file until i make my own
      home.file."${config.programs.nixcord.equibop.configDir}/settings/settings.json".enable =
        lib.mkForce false;

      xdg.autostart.entries = [
        "${config.programs.nixcord.equibop.package}/share/applications/equibop.desktop"
      ];

      # disable until i find a good theme
      stylix.targets.nixcord.enable = false;
    };

  flake-file.inputs.nixcord = {
    url = "github:FlameFlag/nixcord";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
