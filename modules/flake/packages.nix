{ self, inputs, ... }:

{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

  perSystem = { config, self', inputs', pkgs, stable, small, system, ... }: {
    packages = (import ../../pkgs { inherit pkgs stable small; });

    overlayAttrs = config.packages;
  };
}
