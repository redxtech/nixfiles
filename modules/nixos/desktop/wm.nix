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
    services = {
      xserver = {
        enable = true;
        xkb.layout = "us";

        # enable bspwm or gnome if selected
        windowManager.bspwm.enable = isBspwm;

        # disable suspend and screen blanking
        serverFlagsSection = ''
          Option "StandbyTime" "0"
          Option "SuspendTime" "0"
          Option "OffTime" "0"
        '';
      };

      desktopManager.gnome.enable = isGnome;

      displayManager.defaultSession = {
        bspwm = "none+bspwm";
        gnome = "gnome";
        hyprland = "hyprland-uwsm";
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
    programs.hyprland = let
      hyprpkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
    in {
      enable = isHyprland;

      package = hyprpkgs.hyprland;
      portalPackage = hyprpkgs.xdg-desktop-portal-hyprland;

      withUWSM = true;

      # custom module for hyprpolkitagent
      polkitAgent.enable = true;
    };

    xdg.portal = {
      enable = true;

      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      xdgOpenUsePortal = true;

      config.common.default = "*";
    };

    # fix shutdown taking a long time
    # https://gist.github.com/worldofpeace/27fcdcb111ddf58ba1227bf63501a5fe
    systemd.settings.Manager = {
      DefaultTimeoutStopSec = "10s";
      DefaultTimeoutStartSec = "10s";
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
