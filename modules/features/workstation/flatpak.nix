{ inputs, self, ... }:

{
  den.aspects.flatpak = {
    nixos.services.flatpak.enable = true;

    homeManager =
      { config, pkgs, ... }:
      {
        imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

        services.flatpak = {
          enable = true;

          update.auto = {
            enable = true;
            onCalendar = "weekly";
          };

          overrides.settings.global = {
            Context.sockets = [
              "wayland"
              "!x11"
              "!fallback-x11"
            ];

            # fix un-themed cursor in some wayland apps
            Environment.XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
          };

          # TODO: add flatpaks

          # packages = [
          #   "com.getpostman.Postman"
          #   "com.obsproject.Studio"
          #   "io.github.seadve.Kooha"
          # ];
        };

        xdg.dataFile."fonts".source =
          config.lib.file.mkOutOfStoreSymlink /run/current-system/sw/share/X11/fonts;
      };
  };

  flake-file.inputs.nix-flatpak.url = "github:gmodena/nix-flatpak";
}
