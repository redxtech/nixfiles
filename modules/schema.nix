{
  inputs,
  den,
  lib,
  ...
}:

{
  den.schema.host =
    { config, ... }:
    {
      options.settings = lib.mkOption {
        description = "Per-aspect settings namespace";
        default = { };
        type =
          let
            aspectsWithSettings = lib.filterAttrs (_: a: a ? settings) den.aspects;

            # Extract raw option declarations from den's settings wrapper
            extractRawOptions =
              settingsVal:
              let
                outerImports = settingsVal.imports or [ ];
                innerModule = if outerImports != [ ] then builtins.head outerImports else { };
                innerImports = innerModule.imports or [ ];
                rawOpts = if innerImports != [ ] then builtins.head innerImports else { };
              in
              rawOpts;
          in
          lib.types.submodule {
            options = lib.mapAttrs (
              name: aspect:
              lib.mkOption {
                type = lib.types.submodule { options = extractRawOptions aspect.settings; };
                default = { };
                description = "Settings for the ${name} aspect";
              }
            ) aspectsWithSettings;
          };
      };
    };
}
