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
              "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
              "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
              "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
            };
          };
        };

        # for xdg-desktop-portal
        services.gnome.gnome-keyring.enable = true;
      };

    homeManager = {
      xdg.enable = true;
    };
  };
}
