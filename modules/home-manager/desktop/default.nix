{ inputs, pkgs, lib, config, ... }:

{
  imports = [
    # submodules
    ./audio.nix
    ./monitors.nix
  ];

  # TODO:
  # - set up wm config
  # - set up autostarted apps
  # - set up installed apps

  options.desktop = let inherit (lib) mkOption types;
  in {
    enable = lib.mkEnableOption "Enable desktop configuration";
  };

  # config = { };
}
