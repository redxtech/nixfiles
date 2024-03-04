{ inputs, pkgs, ... }:

{
  imports = [ inputs.xremap-flake.nixosModules.default ];

  environment.systemPackages = with pkgs; [
    dunst
    feh
    rofi
    picom
    inputs.sddm-catppuccin.packages.${pkgs.hostPlatform.system}.sddm-catppuccin
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };

  services = {
    xserver = {
      enable = true;

      xkb.layout = "us";

      displayManager = {
        sddm = {
          enable = true;

          theme = "catppuccin";

          wayland.enable = true;

          settings = {
            General = { CursorTheme = "Vimix-Cursors"; };
            Theme = { EnableAvatars = true; };
          };
        };

        defaultSession = "hyprland";
      };
    };

    # modmap for single key rebinds
    xremap.config.modmap = [{
      name = "Global";
      remap = { "CapsLock" = "SUPER_L"; };
    }];

    geoclue2.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;
  };

  # Fix shutdown taking a long time
  # https://gist.github.com/worldofpeace/27fcdcb111ddf58ba1227bf63501a5fe
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=10s
    DefaultTimeoutStartSec=10s
  '';
}