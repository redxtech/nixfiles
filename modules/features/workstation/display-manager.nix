{ inputs, self, ... }:

{
  den.aspects.display-manager = {
    nixos =
      { pkgs, lib, ... }:
      {
        services = {
          greetd = {
            enable = true;

            settings = {
              default_session = {
                # NOTE: moved to window-manager aspect
                # command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri";
                user = "greeter";
              };
            };
          };
        };
      };
  };
}
