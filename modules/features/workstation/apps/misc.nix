{
  den.aspects.misc-apps = {
    nixos =
      { pkgs, ... }:
      {
        programs.localsend.enable = true;
        programs.partition-manager.enable = true;
        # install system-wide so polkit can discover bitwarden's unlock policy.
        environment.systemPackages = [ pkgs.bitwarden-desktop ];
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = with pkgs; [
          # audacity # audio editor
          # beekeeper-studio-ultimate # database manager
          discord # chat
          ente-desktop # photos app
          feishin # music player
          fractal # matrix client
          google-chrome # backup browser
          insomnia # api client
          kooha # simple screen recorder
          gpa # gpg gui
          libreoffice # office suite
          mozillavpn # vpn
          # multiviewer-for-f1 # formula 1 viewer
          # music-assistant-desktop # music-assistant companion app
          # kdePackages.okular # document reader
          pavucontrol # audio control
          pwvucontrol # audio control (pipewire)
          peazip # archive manager
          piper # gui for ratbagd/logitech mouse control
          # postman # api client
          # qdirstat # disk usage analyzer
          seahorse # gpg manager
          tauon # audio player
          via # keyboard flasher
          wev # wayland event viewer
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
