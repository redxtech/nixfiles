{
  den.aspects.kde-connect = {
    # opens ports
    nixos.programs.kdeconnect.enable = true;

    homeManager = {
      services.kdeconnect = {
        enable = true;
        indicator = true;
      };

      # hide all desktop entries, except for org.kde.kdeconnect.settings
      xdg.desktopEntries = {
        "org.kde.kdeconnect.sms" = {
          exec = "";
          name = "KDE Connect SMS";
          settings.NoDisplay = "true";
        };
        "org.kde.kdeconnect.nonplasma" = {
          exec = "";
          name = "KDE Connect Indicator";
          settings.NoDisplay = "true";
        };
        "org.kde.kdeconnect.app" = {
          exec = "";
          name = "KDE Connect";
          settings.NoDisplay = "true";
        };
      };
    };
  };
}
