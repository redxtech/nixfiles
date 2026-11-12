{
  perSystem =
    { pkgs, ... }:
    {
      packages.attic-client-ci = pkgs.attic-client.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [ ./tcp-user-timeout.patch ];
        # the source version follows nixpkgs, not a separate package update
        passthru = builtins.removeAttrs (oldAttrs.passthru or { }) [ "updateScript" ];
      });
    };
}
