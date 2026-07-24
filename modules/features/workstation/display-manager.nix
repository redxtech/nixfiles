{
  den.aspects.display-manager = {
    nixos =
      { pkgs, lib, ... }:
      {
        services = {
          greetd = {
            enable = true;

            # definition moved to window-manager aspect
            # settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri";
            settings.default_session.user = "greeter";
          };
        };
      };
  };
}
