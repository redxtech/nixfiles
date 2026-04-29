{ inputs, ... }:

# make custom lib functions available to all modules
# access with `self.lib`
let
  mkLib = nixpkgs: nixpkgs.lib.extend (final: prev: (import ../lib final));
  customLib = mkLib inputs.nixpkgs;
in
{
  flake.lib = customLib;
}
