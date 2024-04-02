{ self, lib, inputs, ... }:

{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

  perSystem = { config, self', inputs', pkgs, system, ... }: {
    packages = (import ../../pkgs { inherit pkgs; });

    overlayAttrs = config.packages;
  };
}
