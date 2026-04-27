{
  den.aspects.scripts.homeManager =
    { pkgs, lib, ... }:
    {
      options.scripts = {
        enable = lib.mkEnableOption "Enable scripts" // {
          default = true;
        };

        mainPicker = lib.mkOption {
          type = lib.types.package;
          default = pkgs.fuzzel;
          defaultText = "pkgs.fuzzel";
          description = "The main package to use for scripts";
        };

        scripts = lib.mkOption {
          type = lib.types.attrsOf lib.types.package;
          description = "Make scripts available to home-manager";
          default = { };
          example = lib.literalExpression ''
            {
              rofi-applet = pkgs.writeShellApplication { ... };
            }
          '';
        };
      };
    };
}
