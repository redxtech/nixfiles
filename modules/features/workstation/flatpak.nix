{ inputs, ... }:

{
  den.aspects.flatpak = {
    nixos.services.flatpak.enable = true;

    homeManager =
      { config, pkgs, ... }:
      let
        superProductivityAppId = "com.super_productivity.SuperProductivity";
      in
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

          # electron requests this fixed name inside flatpak's PID namespace.
          overrides.settings.${superProductivityAppId}."Session Bus Policy"."org.freedesktop.StatusNotifierItem-3-1" =
            "own";

          packages = [ superProductivityAppId ];
        };

        xdg.dataFile."fonts".source =
          config.lib.file.mkOutOfStoreSymlink /run/current-system/sw/share/X11/fonts;
      };
  };

  flake-file.inputs.nix-flatpak.url = "github:gmodena/nix-flatpak";
}
