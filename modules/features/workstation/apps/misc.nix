{
  den.aspects.misc-apps = {
    nixos =
      { pkgs, ... }:
      {
        programs.localsend.enable = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          # audacity # audio editor
          # beekeeper-studio-ultimate # database manager
          bitwarden-desktop # password manager
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
          # kdePackages.okular # document reader
          pavucontrol # audio control
          pwvucontrol # audio control (pipewire)
          peazip # archive manager
          # piper # gui for ratbagd/logitech mouse control
          # postman # api client
          prismlauncher # minecraft launcher
          # qdirstat # disk usage analyzer
          # via # keyboard flasher
          # TODO: add tauon (with librespot patch)
          xfce4-exo # file opener
        ];

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
