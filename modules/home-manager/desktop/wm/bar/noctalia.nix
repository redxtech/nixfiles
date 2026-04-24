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
    home.packages = with pkgs; [
      inputs.noctalia.packages.${stdenv.hostPlatform.system}.default

      fastfetch
      gpu-screen-recorder
      qt6.qtwebsockets
    ];

    programs.noctalia-shell = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
