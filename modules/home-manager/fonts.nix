{ lib, config, ... }:

let
  mkFontOption = kind:
    with lib; {
      family = mkOption {
        type = types.str;
        default = null;
        description = "Family name for ${kind} font profile";
        example = "Fira Code";
      };
      package = mkOption {
        type = types.package;
        default = null;
        description = "Package for ${kind} font profile";
        example = "pkgs.fira-code";
      };
    };
  cfg = config.fontProfiles;
in with lib; {
  options.fontProfiles = {
    enable = mkEnableOption "Whether to enable font profiles";
    monospace = mkFontOption "monospace";
    regular = mkFontOption "regular";
    symbols = mkFontOption "symbols";
    extraFonts = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra font packages to install";
      example = "pkgs.fira-code";
    };
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;
    home.packages =
      [ cfg.monospace.package cfg.regular.package cfg.symbols.package ]
      ++ cfg.extraFonts;
  };
}
