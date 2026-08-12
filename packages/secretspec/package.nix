{
  perSystem =
    { pkgs, ... }:
    {
      packages.secretspec = pkgs.secretspec.overrideAttrs (oldAttrs: rec {
        version = "0.19.1";

        src = pkgs.fetchFromGitHub {
          owner = "cachix";
          repo = "secretspec";
          tag = "v${version}";
          hash = "sha256-sEr7RtfJhk1f2tOv+ICIEcVHDTYi/VAGKyLcgPeEuKI=";
        };

        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-65XNSpyL9FSVDMfL+TIeh1LJssrvpNVXsP+8jFcCXs0=";
        };
        cargoBuildFlags = [
          "--package"
          "secretspec"
        ];
        cargoTestFlags = cargoBuildFlags;
        dontUseCargoParallelTests = true;
        nativeCheckInputs = oldAttrs.nativeCheckInputs ++ [ pkgs.jq ];
        postPatch = ''
          patchShebangs tests/fixtures/bw-shim.sh
        '';
        preCheck = ''
          export HOME="$TMPDIR"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        '';

        meta = oldAttrs.meta // {
          changelog = "https://github.com/cachix/secretspec/releases/tag/v${version}";
        };
      });
    };
}
