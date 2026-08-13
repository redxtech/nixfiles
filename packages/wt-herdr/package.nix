{
  perSystem =
    {
      inputs',
      lib,
      pkgs,
      packageUpdateScripts,
      ...
    }:
    {
      packages.wt-herdr = pkgs.stdenvNoCC.mkDerivation {
        pname = "wt-herdr";
        version = "0-unstable-2026-06-14";

        src = pkgs.fetchFromGitHub {
          owner = "mattarau";
          repo = "wt-herdr";
          rev = "d2460cc990648892facbc4b99b4eae4407f14536";
          hash = "sha256-mZ5G8hoyZcw5yqyzsM6ErjjFt/TwXAHqN6bVc27Cp88=";
        };

        nativeBuildInputs = [ pkgs.makeWrapper ];
        nativeCheckInputs = [ pkgs.shellcheck ];

        passthru.updateScript = packageUpdateScripts.unstable;

        doCheck = true;
        checkPhase = ''
          runHook preCheck

          # Upstream intentionally expands the optional session prefix into separate arguments.
          shellcheck --exclude=SC2046 wt-herdr

          runHook postCheck
        '';

        installPhase = ''
          runHook preInstall

          install -Dm755 wt-herdr "$out/bin/wt-herdr"
          wrapProgram "$out/bin/wt-herdr" \
            --prefix PATH : ${
              lib.makeBinPath [
                inputs'.llm-agents.packages.herdr
                pkgs.jq
                pkgs.worktrunk
              ]
            }

          runHook postInstall
        '';

        meta.mainProgram = "wt-herdr";
      };
    };
}
