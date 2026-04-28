{
  den.aspects.misc-apps = {
    nixos =
      { pkgs, ... }:
      {
        programs.localsend.enable = true;
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages =
          let
            tauon-with-librespot = pkgs.tauon.overrideAttrs (oldAttrs: {
              buildInputs = oldAttrs.buildInputs ++ [ pkgs.librespot ];
              makeWrapperArgs = oldAttrs.makeWrapperArgs ++ [
                "--prefix PATH : ${lib.makeBinPath [ pkgs.librespot ]}"
                "--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ pkgs.librespot ]}"
              ];
            });
          in
          with pkgs;
          [
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
            # tauon-with-librespot # audio player
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
