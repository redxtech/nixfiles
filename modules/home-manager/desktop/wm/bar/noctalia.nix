{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.desktop;
in
{
  config = lib.mkIf cfg.wm.enable {
    home.packages = [
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      pkgs.gpu-screen-recorder
    ];

    programs.noctalia-shell = {
      enable = true;
    };
  };
}
