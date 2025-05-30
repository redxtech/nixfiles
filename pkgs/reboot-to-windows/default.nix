{
  lib,
  writeShellScriptBin,
  makeDesktopItem,
  fetchurl,
  bootloader-entry ? "auto-windows",
  ...
}:

makeDesktopItem {
  name = "reboot-to-windows";
  type = "Application";
  desktopName = "Reboot to Windows";
  genericName = "reboot to windows";
  comment = "reboot to windows";
  icon = fetchurl {
    url = "https://raw.githubusercontent.com/Wartybix/Reboot-To-Windows/refs/heads/master/icons/reboot-to-windows.svg";
    hash = "sha256-49+Q+C4N8v++U0NW6syVT86ypEbac9HfFRq1cp3+LEU=";
  };
  categories = [ "System" ];
  exec = lib.getExe (
    writeShellScriptBin "reboot-to-windows" ''
      systemctl reboot --boot-loader-entry=${bootloader-entry} > /home/gabe/test.log 2>&1
    ''
  );
}
