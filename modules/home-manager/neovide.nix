{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.neovim.neovide;

  settingsFormat = pkgs.formats.toml { };
  settingsFile = settingsFormat.generate "config.toml" cfg.settings;
in {
  options.programs.neovim.neovide = let inherit (lib) mkEnableOption mkOption;

  in {
    enable = mkEnableOption "Enable neovide";

    settings = mkOption {
      inherit (settingsFormat) type;
      default = { };
      description = lib.mdDoc ''
        Configuration included in `config.toml`.

        See https://neovide.dev/config-file.html for documentation.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ neovide ];

    xdg.configFile."neovide/config.toml".source = settingsFile;
  };
}
