{ inputs, pkgs, lib, config, ... }:

{
  imports = [
    # submodules
    ./apps
    ./audio.nix
    ./autostart.nix
    ./monitors.nix
    ./wm
  ];

  options.desktop = let inherit (lib) mkOption types;
  in {
    enable = lib.mkEnableOption "Enable desktop configuration";

    network = {
      interface = mkOption {
        type = types.str;
        default = null;
        example = "enp39s0";
        description = ''
          The network interface to use for the audio server.
          If null, the default interface will be used.
        '';
      };

      type = mkOption {
        type = types.enum [ "wired" "wireless" ];
        default = null;
        description = ''
          The type of network interface.
        '';
      };
    };
  };

  # config = { };
}
