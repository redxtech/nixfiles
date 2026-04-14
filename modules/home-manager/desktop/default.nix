{ config, lib, ... }:

let
  inherit (lib) mkOption;
in
{
  imports = [
    # submodules
    ./apps
    ./audio.nix
    ./autostart.nix
    ./monitors.nix
    ./services.nix
    ./theme.nix
    ./wm
  ];

  options.desktop = with lib.types; {
    enable = lib.mkEnableOption "Enable desktop configuration";

    isLaptop = mkOption {
      type = bool;
      default = false;
      description = ''
        Whether the system is a laptop.
      '';
      example = true;
    };

    kdeConnect = mkOption {
      type = bool;
      default = false;
      description = "Whether to enable KDE Connect.";
      example = true;
    };
  };
}
