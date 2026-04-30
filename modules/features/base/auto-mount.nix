{
  den.aspects.auto-mount = {
    # required for udiskie to work
    nixos.services.udisks2.enable = true;

    homeManager =
      { pkgs, lib, ... }:
      {
        services.udiskie = {
          enable = true;

          # prevent udiskie from not being albe to find the file manager
          settings.program_options.file_manager = lib.getExe' pkgs.xdg-utils "xdg-open";
        };
      };
  };
}
