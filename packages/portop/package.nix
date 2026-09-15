{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    let
      pname = "portop";
      version = "0.0.5";
    in
    {
      packages.portop = pkgs.buildGoModule {
        inherit pname version;

        src = pkgs.fetchFromGitHub {
          owner = "padovanl";
          repo = "portop";
          tag = "v${version}";
          hash = "sha256-FsDJ+JMa+9M3bub/AYPYfz95ZLPCmoKNw74agM1H1gc=";
        };

        vendorHash = "sha256-aJllcMJduoi8VBWMJWsxm8swXtNonYZzX8etmNZePzc=";

        subPackages = [ "cmd/portop" ];
        env.CGO_ENABLED = 0;

        ldflags = [
          "-s"
          "-w"
          "-X github.com/padovanl/portop/internal/cli.Version=${version}"
        ];

        checkPhase = ''
          runHook preCheck

          go test -count=1 ./...
          go test -tags=e2e -count=1 ./e2e/...

          runHook postCheck
        '';

        doInstallCheck = true;
        nativeInstallCheckInputs = [ pkgs.jq ];
        installCheckPhase = ''
          runHook preInstallCheck

          $out/bin/portop --version | grep -F "portop ${version}"
          $out/bin/portop --json --no-dns --no-systemd --no-docker \
            | jq --exit-status 'type == "array"'

          runHook postInstallCheck
        '';

        passthru.updateScript = packageUpdateScripts.githubRelease;

        meta = {
          description = "TUI for inspecting and controlling processes that use network ports";
          homepage = "https://github.com/padovanl/portop";
          changelog = "https://github.com/padovanl/portop/releases/tag/v${version}";
          license = lib.licenses.mit;
          maintainers = [ lib.maintainers.redxtech ];
          mainProgram = pname;
          platforms = [
            "x86_64-linux"
            "aarch64-linux"
          ];
        };
      };
    };
}
