{ den, lib, ... }:

{
  den.aspects.workstation = {
    settings.isLaptop = lib.mkEnableOption "Whether the host is a laptop";

    includes = [
      den.aspects.base
      den.aspects.display-manager
      den.aspects.window-manager

      den.aspects.audio
      den.aspects.autostart
      den.aspects.bar
      den.aspects.bluetooth
      den.aspects.default-apps
      den.aspects.flatpak
      den.aspects.kde-connect
      den.aspects.monitors
      den.aspects.network
      den.aspects.picker
      den.aspects.screenshot
      den.aspects.scripts
      den.aspects.xdg

      # apps
      den.aspects.browser
      den.aspects.spotify
      den.aspects.discord
      den.aspects.email
      den.aspects.file-browser
      den.aspects.image-viewer
      den.aspects.misc-apps
      den.aspects.terminal
      den.aspects.video-player

      # include workstation-only sub-aspects
      den.aspects.editor._.for-workstation
    ];
  };
}
