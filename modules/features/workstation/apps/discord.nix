{ inputs, ... }:

{
  # TODO: rename to chat, add element
  den.aspects.discord = {
    # block discord from changing mic input volume
    nixos.services.pipewire.extraConfig.pipewire-pulse."10-disable-discord-volume-control"."pulse.rules" =
      [
        # rule for equibop & vesktop
        {
          matches = [
            { "application.process.binary" = "electron"; }
          ];
          actions = {
            quirks = [ "block-source-volume" ];
          };
        }
        # rule for official discord client
        {
          matches = [
            { "application.process.binary" = ".Discord-wrapped"; }
          ];
          actions = {
            quirks = [ "block-source-volume" ];
          };
        }
      ];

    homeManager =
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
        };

        # disable generating settings file until i make my own
        home.file."${config.programs.nixcord.equibop.configDir}/settings/settings.json".enable =
          lib.mkForce false;

        xdg.autostart.entries = [
          "${config.programs.nixcord.equibop.package}/share/applications/equibop.desktop"
        ];

        home.packages = with pkgs; [ element-desktop ];

        # disable until i find a good theme
        stylix.targets.nixcord.enable = false;
      };
  };

  flake-file.inputs.nixcord = {
    url = "github:FlameFlag/nixcord";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
