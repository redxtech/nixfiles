{
  den.aspects.misc-apps = {
    nixos =
      { pkgs, ... }:
      {
        programs.localsend.enable = true;
        programs.partition-manager.enable = true;
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = with pkgs; [
          # audacity # audio editor
          # beekeeper-studio-ultimate # database manager
          # bitwarden-desktop # password manager # TODO: re-enable when it doesn't use electron_39
          # discord # chat
          # ente-desktop # photos app
          # feishin # music player
          # google-chrome # backup browser
          insomnia # api client
          kooha # simple screen recorder
          gpa # gpg gui
          # libreoffice # office suite
          mozillavpn # vpn
          # multiviewer-for-f1 # formula 1 viewer
          # music-assistant-desktop # music-assistant companion app
          # kdePackages.okular # document reader
          pavucontrol # audio control
          pwvucontrol # audio control (pipewire)
          peazip # archive manager
          # piper # gui for ratbagd/logitech mouse control
          # postman # api client
          prismlauncher # minecraft launcher
          # qdirstat # disk usage analyzer
          # super-productivity # productivity app
          tauon # audio player
          # via # keyboard flasher
          wev # wayland event viewer
          xfce4-exo # file opener
        ];

        services.keybase.enable = true;

        programs.zathura = {
          enable = true;
          options = {
            window-title-basename = true;
            window-title-home-tilde = true;
            selection-clipboard = "clipboard";
          };
        };
      };
  };
}
