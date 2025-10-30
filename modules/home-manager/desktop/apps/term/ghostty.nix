{ config, lib, pkgs, ... }:

let
  cfg = config.desktop;
  ghosttyShaders = pkgs.fetchFromGitHub {
    owner = "sahaj-b";
    repo = "ghostty-cursor-shaders";
    rev = "4faa83e4b9306750fc8de64b38c6f53c57862db8";
    hash = "sha256-ruhEqXnWRCYdX5mRczpY3rj1DTdxyY3BoN9pdlDOKrE=";
  };
in {
  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;

      settings = {
        theme = "Dracula";
        background-opacity = 0.8;
        background-opacity-cells = true;

        font-family = config.fontProfiles.monospace.family;
        font-size = 13;

        cursor-style = "bar";

        window-vsync = false;
        window-height = "30";
        window-width = "115";

        quit-after-last-window-closed = false;

        desktop-notifications = true;

        custom-shader-animation = "always";
        custom-shader = [ "${ghosttyShaders}/cursor_sweep.glsl" ];
      };

      enableFishIntegration = true;
      installBatSyntax = true;
      installVimSyntax = true;
    };

    systemd.user.services.ghostty = {
      Unit = {
        Description = "ghostty daemon";
        After = [ "graphical-session.target" "dbus.socket" ];
        Requires = [ "dbus.socket" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        Type = "notify-reload";
        ReloadSignal = "SIGUSR2";
        BusName = "com.mitchellh.ghostty";
        ExecStart =
          "${config.programs.ghostty.package}/bin/ghostty --gtk-single-instance=true --initial-window=false";
      };
    };
  };
}

