{ lib, writeShellScriptBin, makeDesktopItem, fetchurl, systemd, polkit
, bootloader-entry ? "auto-windows", ... }:

makeDesktopItem {
  name = "reboot-to-windows";
  type = "Application";
  desktopName = "Reboot to Windows";
  genericName = "reboot to windows";
  comment = "reboot to windows";
  icon = let
    icon = fetchurl {
      url =
        "https://raw.githubusercontent.com/Wartybix/Reboot-To-Windows/refs/heads/master/icons/reboot-to-windows.svg";
      hash = "sha256-49+Q+C4N8v++U0NW6syVT86ypEbac9HfFRq1cp3+LEU=";
    };
  in icon;
  categories = [ "System" ];
  exec = let
    reboot-to-windows = writeShellScriptBin "reboot-to-windows" ''
      systemctl reboot --boot-loader-entry=${bootloader-entry} > /home/gabe/test.log 2>&1
    '';
  in lib.getExe reboot-to-windows;
}
