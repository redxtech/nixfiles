{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [ dunst feh rofi picom polkit_gnome ];

  services = {
    xserver = {
      enable = true;

      layout = "us";
      # xkbVariant = "";

      displayManager = {
        sddm = {
          enable = false;
          theme = "chili";
          # theme = "sddm-chili-theme";
          # theme = "catppuccin-sddm-corners";
        };

        gdm = {
          enable = true;
          autoSuspend = false;
        };

        # defaultSession = "bspwm";
      };

      windowManager.bspwm.enable = true;

      libinput = {
        enable = true;
        touchpad = {
          naturalScrolling = true;
          # disableWhileTyping = true;
        };
      };
    };

    geoclue2.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
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

    # Fix shutdown taking a long time
    # https://gist.github.com/worldofpeace/27fcdcb111ddf58ba1227bf63501a5fe
    extraConfig = ''
      DefaultTimeoutStopSec=10s
      DefaultTimeoutStartSec=10s
    '';
  };

}
