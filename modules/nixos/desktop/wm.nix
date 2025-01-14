{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf optionals;
  cfg = config.desktop;
in {
  options.desktop = let inherit (lib) mkOption types;
  in with types; {
    wm = mkOption {
      type = enum [ "bspwm" "hyprland" "gnome" ];
      default = null;
      description = ''
        The window manager to use.
      '';
    };
  };

  config = let
    isBspwm = cfg.wm == "bspwm";
    isHyprland = cfg.wm == "hyprland";
    isGnome = cfg.wm == "gnome";
  in mkIf cfg.enable {
    services = {
      xserver = {
        enable = true;
        xkb.layout = "us";

        # enable bspwm or gnome if selected
        windowManager.bspwm.enable = isBspwm;
        desktopManager.gnome.enable = isGnome;

        # disable suspend and screen blanking
        serverFlagsSection = ''
          Option "StandbyTime" "0"
          Option "SuspendTime" "0"
          Option "OffTime" "0"
        '';
      };

      displayManager.defaultSession = {
        bspwm = "none+bspwm";
        gnome = "gnome";
        hyprland = "hyprland";
      }.${cfg.wm};

      libinput = {
        enable = true;
        touchpad = {
          naturalScrolling = true;
          # disableWhileTyping = true;
        };
      };
    };

    # enable hyprland if selected
    programs.hyprland.enable = isHyprland;

    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart =
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };

      # fix shutdown taking a long time
      # https://gist.github.com/worldofpeace/27fcdcb111ddf58ba1227bf63501a5fe
      extraConfig = ''
        DefaultTimeoutStopSec=10s
        DefaultTimeoutStartSec=10s
      '';
    };

    environment.sessionVariables.NIXOS_OZONE_WL =
      mkIf (isHyprland || isGnome) "1";

    environment.systemPackages = with pkgs;
      ([ ] ++ (optionals isBspwm [ dunst picom polkit_gnome ])
        ++ (optionals isHyprland [ ]) ++ (optionals isGnome [
          gpaste
          gnome-tweaks

          gnomeExtensions.appindicator
          gnomeExtensions.blur-my-shell
          gnomeExtensions.caffeine
          gnomeExtensions.clipboard-indicator
          gnomeExtensions.docker
          gnomeExtensions.focus-changer
          # gnomeExtensions.gesture-improvements # TODO: find replacement
          gnomeExtensions.grand-theft-focus
          gnomeExtensions.just-perfection
          gnomeExtensions.no-titlebar-when-maximized
          # gnomeExtensions.openweather
          gnomeExtensions.pip-on-top
          gnomeExtensions.power-profile-switcher
          gnomeExtensions.switch-focus-type
          # gnomeExtensions.workspace-indicator-2
          gnomeExtensions.vitals
        ]));
  };
}
