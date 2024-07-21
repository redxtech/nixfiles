{ self, inputs, ... }:

{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

  perSystem = { config, self', inputs', pkgs, stable, system, ... }: {
    packages = (import ../../pkgs { inherit pkgs stable; });

    overlayAttrs = config.packages;
  };
}
