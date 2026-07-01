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
    ];

    programs.noctalia = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

      systemd.enable = true;
    };
  };
}
