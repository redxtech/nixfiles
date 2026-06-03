{
  den,
  lib,
  ...
}:

let
  # Dynamic settings type — recursively discovers aspects that declare .settings.
  # Mirrors the aspect tree: den.aspects.disk.zfs-disk-single.settings →
  # host.settings.disk.zfs-disk-single.*
  settingsType =
    let
      inherit (lib) mkOption types;
      inherit (den.lib.aspects.fx.keyClassification) structuralKeysSet;
      classKeys = den.classes or { };
      quirkKeys = den.quirks or { };
      skipKey = k: structuralKeysSet ? ${k} || classKeys ? ${k} || quirkKeys ? ${k};

      # Settings declarations may be plain option attrsets
      # (`{ foo = mkOption {...}; }`) or module-shaped with explicit
      # imports/config. Default the module keys so plain attrsets work.
      reshapeSettings = raw: {
        imports = raw.imports or [ ];
        config = raw.config or { };
        options = removeAttrs raw [
          "imports"
          "config"
        ];
      };

      # Recursively build a nested submodule type mirroring the aspect tree.
      # At each level: if the aspect has .settings, declare those options.
      # If it has children, recurse into them as nested submodule options.
      buildSettingsModule =
        aspects:
        let
          children = lib.filterAttrs (k: v: builtins.isAttrs v && !(skipKey k)) aspects;
          withSettings = lib.filterAttrs (_: a: builtins.isAttrs a && a ? settings) aspects;
        in
        types.submodule {
          options =
            # Leaf settings: aspect has .settings → declare those options here
            lib.mapAttrs (
              name: aspect:
              mkOption {
                type = types.submodule (reshapeSettings aspect.settings);
                default = { };
                description = "Settings for the ${name} aspect";
              }
            ) withSettings
            # Nested categories: recurse into children that have further aspects
            //
              lib.mapAttrs
                (
                  name: child:
                  mkOption {
                    type = buildSettingsModule child;
                    default = { };
                    description = "Settings under ${name}";
                  }
                )
                (
                  lib.filterAttrs (
                    k: v:
                    !(withSettings ? ${k})
                    && builtins.isAttrs v
                    && !(skipKey k)
                    && lib.any (ck: builtins.isAttrs (v.${ck} or null) && (v.${ck} ? settings)) (builtins.attrNames v)
                  ) children
                );
        };
    in
    buildSettingsModule (den.aspects or { });
in
{
  den.schema.host.imports = [
    (
      { config, ... }:
      {
        options = {
          # Dynamic settings namespace — auto-discovers aspects with .settings
          settings =
            lib.mkOption {
              type = settingsType;
              default = { };
              description = "Per-aspect typed settings";
            }
            // {
              identity = false;
            };
        };
      }
    )
  ];
}
