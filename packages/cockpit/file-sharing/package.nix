{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.cockpit-file-sharing =
        let
          inherit (pkgs)
            stdenv
            fetchurl
            dpkg
            ;

          pname = "cockpit-file-sharing";
          version = "4.6.3";
          updateScript = packageUpdateScripts.nodeScript {
            packageName = pname;
            script = ./update.mjs;
            args = [ "packages/cockpit/file-sharing/package.nix" ];
            runtimeInputs = [ pkgs.nix ];
          };
        in
        stdenv.mkDerivation {
          inherit pname version;

          src = fetchurl {
            url = "https://github.com/45Drives/cockpit-file-sharing/releases/download/v4.6.3/cockpit-file-sharing_4.6.3-1bookworm_all.deb";
            hash = "sha256-hM4tkJqsM/7oWfy4YAsAo9EKVLXEw8qcbPgtO+z9nfY=";
          };

          nativeBuildInputs = [ dpkg ];

          passthru.updateScript = lib.getExe updateScript;

          unpackPhase = "true";

          installPhase = ''
            mkdir -p $out deb
            dpkg -x $src deb
            cp -r deb/usr/share $out
            ls -al $out
          '';

          meta = with lib; {
            description = "Cockpit UI for managing shares";
            homepage = "https://github.com/45Drives/cockpit-file-sharing";
            license = licenses.gpl3Only;
            maintainers = with lib.maintainers; [ redxtech ];
            platforms = platforms.linux;
          };
        };
    };
}
