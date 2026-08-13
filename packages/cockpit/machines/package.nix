{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.cockpit-machines =
        let
          inherit (pkgs)
            cockpit
            fetchFromGitHub
            gettext
            libosinfo
            nodejs
            osinfo-db
            stdenv
            writeShellScriptBin
            ;
        in
        stdenv.mkDerivation (finalAttrs: {
          pname = "cockpit-machines";
          version = "355";

          src = fetchFromGitHub {
            owner = "cockpit-project";
            repo = "cockpit-machines";
            tag = finalAttrs.version;
            hash = "sha256-9NRpo9j0EDTWvJAPuAhr3H6Gigt7MdwYbdXZeGqHVGo=";

            fetchSubmodules = true;
            postFetch = "cp $out/node_modules/.package-lock.json $out/package-lock.json";
          };

          buildInputs = [
            nodejs
            gettext
            (writeShellScriptBin "git" "true")
          ];

          cockpitSrc = cockpit.src;

          postPatch = ''
            mkdir -p pkg; cp -r $cockpitSrc/pkg/lib pkg
            mkdir -p test; cp -r $cockpitSrc/test/common test

            substituteInPlace Makefile \
              --replace-fail '$(MAKE) package-lock.json' 'true' \
              --replace-fail '$(COCKPIT_REPO_FILES) | tar x' "" \
              --replace-fail '/usr/local' "$out"

            substituteInPlace src/manifest.json \
              --replace-fail '"/usr/share/dbus-1/system.d/org.libvirt.conf"' '"/etc/systemd/system/libvirt-dbus.service"'

            patchShebangs build.js
          '';

          passthru = {
            updateScript = packageUpdateScripts.githubRelease;
            cockpitPath = [
              libosinfo
              osinfo-db
            ];
          };

          meta = with lib; {
            description = "Cockpit UI for virtual machines";
            homepage = "https://github.com/cockpit-project/cockpit-machines";
            changelog = "https://github.com/cockpit-project/cockpit-machines/releases/tag/${finalAttrs.version}";
            platforms = platforms.linux;
            license = licenses.lgpl21;
            maintainers = with maintainers; [ redxtech ];
          };
        });
    };
}
