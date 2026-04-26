{
  iosevka,
  cores ? 8,
  ...
}:

(iosevka.override {
  set = "Custom";
  privateBuildPlan = {
    family = "Iosevka Custom";
    spacing = "quasi-proportional";
    serifs = "sans";
    noCvSs = false;
    exportGlyphNames = true;

    variants = {
      inherits = "ss09";
      widths = {
        Condensed = {
          shape = 500;
          menu = 3;
          css = "condensed";
        };
        Normal = {
          shape = 600;
          menu = 5;
          css = "normal";
        };
      };
    };
  };
}).overrideAttrs
  (oldAttrs: {
    # takes previous buildPhase and substitites "$NIX_BUILD_CORES" with the number of cores
    buildPhase =
      builtins.replaceStrings [ "$NIX_BUILD_CORES" ] [ "${toString cores}" ]
        oldAttrs.buildPhase;
  })
