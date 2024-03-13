{ inputs, pkgs, lib, config, ... }:

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

    services.xserver = {
      enable = true;
      xkb.layout = "us";

      windowManager.bspwm.enable = true;
      desktopManager.gnome.enable = true;

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

      # disable suspend and screen blanking
      serverFlagsSection = ''
        Option "StandbyTime" "0"
        Option "SuspendTime" "0"
        Option "OffTime" "0"
      '';
    };

    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

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

    environment.sessionVariables.NIXOS_OZONE_WL = mkIf isHyprland "1";

    environment.systemPackages = with pkgs;
      ([ feh rofi ] ++ (optionals isBspwm [
        dunst
        picom
        inputs.sddm-catppuccin.packages.${pkgs.hostPlatform.system}.sddm-catppuccin
        polkit_gnome
      ]) ++ (optionals isHyprland [
        dunst
        picom
        inputs.sddm-catppuccin.packages.${pkgs.hostPlatform.system}.sddm-catppuccin
      ]) ++ (optionals isGnome (with gnome; [
        gpaste
        gnome3.gnome-tweaks

        gnomeExtensions.appindicator
        gnomeExtensions.blur-my-shell
        gnomeExtensions.caffeine
        gnomeExtensions.clipboard-indicator
        gnomeExtensions.docker
        gnomeExtensions.focus-changer
        gnomeExtensions.forge
        gnomeExtensions.gesture-improvements
        gnomeExtensions.grand-theft-focus
        gnomeExtensions.just-perfection
        gnomeExtensions.no-titlebar-when-maximized
        gnomeExtensions.openweather
        gnomeExtensions.pip-on-top
        gnomeExtensions.power-profile-switcher
        gnomeExtensions.remmina-search-provider
        gnomeExtensions.switch-focus-type
        # gnomeExtensions.system76-scheduler
        gnomeExtensions.workspace-indicator-2
        gnomeExtensions.vitals
        gnomeExtensions.x11-gestures
      ])));
  };
}
