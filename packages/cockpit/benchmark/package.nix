{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.cockpit-benchmark =
        let
          inherit (pkgs)
            stdenv
            fetchurl
            dpkg
            ;

          pname = "cockpit-benchmark";
          version = "2.1.3";
        in
        stdenv.mkDerivation {
          inherit pname version;

          src = fetchurl {
            url = "https://github.com/45Drives/cockpit-benchmark/releases/download/v${version}/cockpit-benchmark_${version}-1focal_all.deb";
            sha256 = "sha256-Wci5IAPMyC1kKjDmFUUAvcxNmkJLuUSXWfx/XT1FzzM=";
          };
          nativeBuildInputs = [ dpkg ];

          passthru.updateScript = packageUpdateScripts.githubRelease;

          unpackPhase = "true";

          installPhase = ''
            mkdir -p $out deb
            dpkg -x $src deb
            cp -r deb/usr/share $out
            ls -al $out
          '';

          meta = with lib; {
            description = "Cockpit UI for benchmarking storage";
            homepage = "https://github.com/45Drives/cockpit-benchmark";
            license = licenses.gpl3Only;
            maintainers = with lib.maintainers; [ redxtech ];
            platforms = platforms.linux;
          };
        };
    };
}
