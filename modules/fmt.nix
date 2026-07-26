{ inputs, ... }:

{
  # TODO: properly setup pedantix
  imports = [
    inputs.treefmt-nix.flakeModule
    # inputs.pedantix.flakeModules.default
  ];

  perSystem =
    { pkgs, lib, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = pkgs.lib.meta.availableOn pkgs.stdenv.buildPlatform pkgs.nixfmt.compiler;
        programs.nixfmt.package = pkgs.nixfmt;
        # programs.pendantix.enable = false;
        programs.shellcheck.enable = true;
      };
    };

  flake-file.inputs = {
    # pedantix.url = "github:swarsel/pedantix";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
