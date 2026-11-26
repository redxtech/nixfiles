{
  perSystem =
    {
      lib,
      pkgs,
      packageUpdateScripts,
      ...
    }:
    {
      packages.mouse-debounce = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
        pname = "mouse-debounce";
        version = "0.2.5";

        src = pkgs.fetchFromGitHub {
          owner = "mishl-dev";
          repo = "mouse-debounce";
          tag = "v${finalAttrs.version}";
          hash = "sha256-XLihsdJs86otRdCdPy4hkwwF8zycCX66A7C822oknI4=";
        };

        patches = [ ./release-only-debounce.patch ];

        cargoHash = "sha256-v1vSCWKP+g1/fvjOGQReaAQZsESMagIINGRj81ACbk4=";

        passthru.updateScript = packageUpdateScripts.githubTag;

        meta = {
          description = "Mouse button debounce daemon for Linux";
          homepage = "https://github.com/mishl-dev/mouse-debounce";
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = "mouse-debounce";
          platforms = lib.platforms.linux;
        };
      });
    };
}
