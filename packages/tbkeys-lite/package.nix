{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    let
      addonId = "tbkeys-lite@addons.thunderbird.net";
      version = "2.4.3";
    in
    {
      packages.tbkeys-lite = pkgs.stdenvNoCC.mkDerivation {
        inherit version;
        pname = "tbkeys-lite";

        src = pkgs.fetchFromGitHub {
          owner = "wshanks";
          repo = "tbkeys";
          tag = "v${version}";
          hash = "sha256-bCzjsVf0IadtXLtFPppiV+zIwFnD6LKCrDWPDTpqA94=";
        };

        patches = [ ./thunderbird-compatibility.patch ];

        nativeBuildInputs = [ pkgs.zip ];

        buildPhase = ''
          runHook preBuild

          make tbkeys-lite

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          install -Dm644 build/tbkeys-lite.xpi \
            "$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}/${addonId}.xpi"

          runHook postInstall
        '';

        passthru = {
          inherit addonId;
          updateScript = packageUpdateScripts.githubRelease;
        };

        meta = {
          description = "Custom Thunderbird keybindings with managed storage support";
          homepage = "https://github.com/wshanks/tbkeys";
          license = lib.licenses.mpl20;
          platforms = lib.platforms.all;
        };
      };
    };
}
