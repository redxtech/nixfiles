{ inputs, self, ... }:

{
  den.aspects.xdg = {
    nixos =
      { pkgs, ... }:
      {
        xdg.portal = {
          xdgOpenUsePortal = true;

          extraPortals = with pkgs; [
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
            gnome-keyring
          ];

          config = {
            common = {
              default = [
                "gtk"
                "gnome"
              ];
              "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
              "org.freedesktop.impl.portal.FileChooser" = [
                "luciole"
                "gtk"
              ];
              "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
              "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
            };

            # niri's desktop-specific file takes precedence over the shared defaults
            niri = {
              default = [
                "gnome"
                "gtk"
              ];
              "org.freedesktop.impl.portal.Access" = [ "gtk" ];
              "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
              "org.freedesktop.impl.portal.Secret" = [
                "oo7-portal"
                "gnome-keyring"
              ];
              "org.freedesktop.impl.portal.FileChooser" = [
                "luciole"
                "gtk"
              ];
            };
          };
        };

        # for xdg-desktop-portal
        services.gnome.gnome-keyring.enable = true;
      };

    homeManager = {
      xdg = {
        enable = true;

        userDirs = {
          enable = true;
          setSessionVariables = true;
        };
      };
    };
  };
}
