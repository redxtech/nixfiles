{
  perSystem =
    {
      self',
      pkgs,
      lib,
      ...
    }:
    let
      cacheSystem = pkgs.writeShellApplication {
        name = "cache-system";
        runtimeInputs = [
          self'.packages.attic-client-ci
          pkgs.coreutils
          pkgs.nix
        ];
        text = builtins.readFile ./cache-system.sh;
      };
    in
    {
      apps.cache-system = {
        type = "app";
        program = lib.getExe cacheSystem;
        meta.description = "build and cache a nixos system on quasar";
      };
    };
}
