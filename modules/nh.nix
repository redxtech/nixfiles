# exposes flake apps under the name of each host / home for building with nh.
# nix run .#<hostname> will build the derivation for the host, and
# nix run .#<hostname> switch will build and activate it
{ den, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = den.lib.nh.denPackages { fromFlake = true; } pkgs;
    };
}
