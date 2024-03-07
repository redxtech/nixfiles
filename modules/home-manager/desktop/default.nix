{ inputs, pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkOption;
  cfg = config.desktop;
in {
  imports = [
    # submodules
    ./apps
    ./audio.nix
    ./autostart.nix
    ./monitors.nix
    ./wm
  ];

  options.desktop = with lib.types; {
    enable = lib.mkEnableOption "Enable desktop configuration";

    network = {
      interface = mkOption {
        type = str;
        default = null;
        example = "enp39s0";
        description = ''
          The network interface to use for the audio server.
          If null, the default interface will be used.
        '';
      };

      type = mkOption {
        type = enum [ "wired" "wireless" ];
        default = null;
        description = ''
          The type of network interface.
        '';
      };
    };
  };

  # config = mkIf cfg.enable { };
}
