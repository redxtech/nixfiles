{
  perSystem =
    {
      pkgs,
      packageUpdateScripts,
      ...
    }:
    {
      packages.secretspec = pkgs.secretspec.overrideAttrs (oldAttrs: rec {
        version = "0.21.1";

        src = pkgs.fetchFromGitHub {
          owner = "cachix";
          repo = "secretspec";
          tag = "v${version}";
          hash = "sha256-8OC1WS8VWTSwUJlT/qWx9CCPmO90G2OWJxEKZGUgXqM=";
        };

        cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
          inherit src;
          hash = "sha256-48k3UKeT8qjRRLrf5yqmxULIynD6FgXiW063VEoTqmU=";
        };
        cargoBuildFlags = [
          "--package"
          "secretspec"
        ];
        cargoTestFlags = cargoBuildFlags;
        dontUseCargoParallelTests = true;
        nativeCheckInputs = oldAttrs.nativeCheckInputs ++ [ pkgs.jq ];
        postPatch = ''
          # the test binary embeds this fixture, so patch it before cargo builds
          test -f secretspec/tests/fixtures/bw-shim.sh
          patchShebangs --build secretspec/tests/fixtures/bw-shim.sh
        '';
        preCheck = ''
          export HOME="$TMPDIR"
          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
          # report assertions expect plain text even when build stdout is a terminal
          export NO_COLOR=1
          export CLICOLOR_FORCE=0
        '';

        passthru = (oldAttrs.passthru or { }) // {
          updateScript = packageUpdateScripts.githubRelease;
        };

        meta = oldAttrs.meta // {
          changelog = "https://github.com/cachix/secretspec/releases/tag/v${version}";
        };
      });
    };
}
