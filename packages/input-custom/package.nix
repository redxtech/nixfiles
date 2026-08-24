{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) lib;

      inputCustom =
        {
          alternates ? { },
          fontSelection ? "whole",
          line-height ? 1.2,
        }:
        let
          # these are the upstream inputCustomize.py values; "0" keeps the original glyph.
          alternateSpec = {
            a = {
              default = "0";
              values = [
                "0"
                "ss"
              ];
            };
            g = {
              default = "ss";
              values = [
                "0"
                "ss"
              ];
            };
            i = {
              default = "serifs_round";
              values = [
                "0"
                "serif"
                "serifs"
                "serifs_round"
                "topserif"
              ];
            };
            l = {
              default = "serifs_round";
              values = [
                "0"
                "serif"
                "serifs"
                "serifs_round"
                "topserif"
              ];
            };
            zero = {
              default = "slash";
              values = [
                "0"
                "nodot"
                "slash"
              ];
            };
            asterisk = {
              default = "0";
              values = [
                "0"
                "height"
              ];
            };
            braces = {
              default = "0";
              values = [
                "0"
                "straight"
              ];
            };
          };
          fontSelectionSpec = {
            whole = {
              description = "all 168 input styles";
              useInstalledFonts = true;
              fontPaths = [ ];
              customizeArguments = [ ];
            };
            basic = {
              description = "the standard mono regular, italic, bold, and bold italic family";
              useInstalledFonts = false;
              fontPaths = [
                "Input_Fonts/InputMono/InputMono/InputMono-Regular.ttf"
                "Input_Fonts/InputMono/InputMono/InputMono-Italic.ttf"
                "Input_Fonts/InputMono/InputMono/InputMono-Bold.ttf"
                "Input_Fonts/InputMono/InputMono/InputMono-BoldItalic.ttf"
              ];
              customizeArguments = [ "--fourStyleFamily" ];
            };
          };
          availableFontSelections = builtins.attrNames fontSelectionSpec;
          selectedFontSelection =
            assert lib.assertMsg (builtins.hasAttr fontSelection fontSelectionSpec)
              "input-custom: fontSelection must be one of ${builtins.concatStringsSep ", " availableFontSelections}";
            fontSelection;
          selectedFontSelectionSpec = fontSelectionSpec.${selectedFontSelection};
          availableLineHeights = [
            0.9
            1.0
            1.1
            1.2
            1.3
            1.4
            1.5
            1.6
            1.7
            1.8
          ];
          selectedLineHeight =
            assert lib.assertMsg (builtins.elem line-height availableLineHeights)
              "input-custom: line-height must be one of ${builtins.concatStringsSep ", " (builtins.map builtins.toString availableLineHeights)}";
            line-height;
          unknownAlternates = lib.filter (name: !builtins.hasAttr name alternateSpec) (
            builtins.attrNames alternates
          );
          selectedAlternates =
            assert lib.assertMsg (
              unknownAlternates == [ ]
            ) "input-custom: unknown alternate options: ${builtins.concatStringsSep ", " unknownAlternates}";
            lib.mapAttrs (
              name: spec:
              let
                value = alternates.${name} or spec.default;
              in
              assert lib.assertMsg (builtins.elem value spec.values)
                "input-custom: ${name} must be one of ${builtins.concatStringsSep ", " spec.values}";
              value
            ) alternateSpec;
          customizeArguments =
            lib.concatLists (
              lib.mapAttrsToList (
                name: value: lib.optional (value != "0") "--${name}=${value}"
              ) selectedAlternates
            )
            ++ [ "--lineHeight=${builtins.toString selectedLineHeight}" ];
          python = pkgs.python3.withPackages (pythonPackages: [ pythonPackages.fonttools ]);
        in
        pkgs.input-fonts.overrideAttrs (oldAttrs: {
          pname = "input-custom";
          outputs = (oldAttrs.outputs or [ "out" ]) ++ [ "collection" ];

          # the bundled customizer targets python 2.6, which nixpkgs no longer provides.
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace Scripts/inputCustomize.py \
              --replace-fail "print doc" "print(doc)" \
              --replace-fail "print os.path.split(path)[1]" "print(os.path.split(path)[1])" \
              --replace-fail "swapMap.has_key(gname)" "gname in swapMap" \
              --replace-fail "print 'done'" "print('done')"
          '';

          postInstall = (oldAttrs.postInstall or "") + ''
            fontDirectory="$out/share/fonts/truetype"
            selectionArguments=()

            if ${lib.boolToString selectedFontSelectionSpec.useInstalledFonts}; then
              fontPaths=("$fontDirectory"/*.ttf)
            else
              rm "$fontDirectory"/*.ttf
              fontPaths=(${lib.escapeShellArgs selectedFontSelectionSpec.fontPaths})
              selectionArguments=(
                ${lib.escapeShellArgs selectedFontSelectionSpec.customizeArguments}
                "--dest=$fontDirectory"
              )
            fi

            ${python}/bin/python3 Scripts/inputCustomize.py \
              "''${fontPaths[@]}" \
              ${lib.escapeShellArgs customizeArguments} \
              "''${selectionArguments[@]}"

            collectionDirectory="$collection/share/fonts/truetype"
            mkdir -p "$collectionDirectory"

            ${python}/bin/python3 - \
              "$collectionDirectory/InputCustom.ttc" \
              "$fontDirectory"/*.ttf <<'PY'
            import sys

            from fontTools.ttLib import TTCollection, TTFont

            collection = TTCollection()
            collection.fonts = [TTFont(path) for path in sys.argv[2:]]
            collection.save(sys.argv[1])
            collection.close()
            PY
          '';

          passthru = (oldAttrs.passthru or { }) // {
            inherit
              alternateSpec
              availableFontSelections
              fontSelectionSpec
              availableLineHeights
              selectedAlternates
              selectedFontSelection
              selectedFontSelectionSpec
              selectedLineHeight
              ;
          };

          meta = oldAttrs.meta // {
            description = "Input fonts with configurable selection, spacing, and letter forms";
          };
        });
    in
    {
      packages.input-custom = lib.makeOverridable inputCustom { };
    };
}
