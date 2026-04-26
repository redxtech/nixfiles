{ inputs, ... }:

{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem =
    { pkgs, lib, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = pkgs.lib.meta.availableOn pkgs.stdenv.buildPlatform pkgs.nixfmt.compiler;
        programs.nixfmt.package = pkgs.nixfmt;
        programs.shellcheck.enable = true;
      };
    };
}
