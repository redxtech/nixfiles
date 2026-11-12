{
  perSystem =
    { pkgs, ... }:
    {
      packages.attic-server = pkgs.attic-server.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url = "https://github.com/redxtech/attic/commit/9756bdb54c7871fe5422675adb61e30c8370ea62.patch";
            hash = "sha256-gncCjvP2kMDebEnfnAyL7oiHVy+SA7VhfvW6V1yxilI=";
          })
        ];

        doCheck = pkgs.stdenv.buildPlatform.canExecute pkgs.stdenv.hostPlatform;
        cargoTestFlags = [
          "--package"
          "attic-server"
          "--lib"
        ];

        # keep the reviewed patch pinned until the maintenance fix is upstream
        passthru = builtins.removeAttrs (oldAttrs.passthru or { }) [ "updateScript" ];
      });
    };
}
