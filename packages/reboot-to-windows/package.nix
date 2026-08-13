{
  perSystem =
    {
      pkgs,
      packageUpdateScripts,
      ...
    }:
    {
      packages.reboot-to-windows =
        let
          inherit (pkgs)
            fetchFromGitHub
            lib
            makeDesktopItem
            writeShellScriptBin
            ;

          bootloader-entry = "auto-windows";
          version = "1.5";
          src = fetchFromGitHub {
            owner = "Wartybix";
            repo = "Reboot-To-Windows";
            tag = version;
            hash = "sha256-8Fawj2mie0VXEFyY0my3tMG5+1F+YvbgMDaq2g/1rnI=";
          };
        in
        (makeDesktopItem {
          name = "reboot-to-windows";
          type = "Application";
          desktopName = "Reboot to Windows";
          genericName = "reboot to windows";
          comment = "reboot to windows";
          icon = "${src}/icons/reboot-to-windows.svg";
          categories = [ "System" ];
          exec = lib.getExe (
            writeShellScriptBin "reboot-to-windows" ''
              systemctl reboot --boot-loader-entry=${bootloader-entry} > /home/gabe/test.log 2>&1
            ''
          );
        }).overrideAttrs
          {
            inherit version src;
            passthru.updateScript = packageUpdateScripts.githubRelease;
          };
    };
}
