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
      den.aspects.default-apps
      den.aspects.devices
      den.aspects.flatpak
      den.aspects.gaming
      den.aspects.kde-connect
      den.aspects.monitors
      den.aspects.mouse
      den.aspects.picker
      den.aspects.power
      den.aspects.remaps
      den.aspects.screenshot
      den.aspects.scripts
      den.aspects.xdg

      # apps
      den.aspects.browser
      den.aspects.chat
      den.aspects.email
      den.aspects.file-browser
      den.aspects.image-viewer
      den.aspects.misc-apps
      den.aspects.screen-recorder
      den.aspects.spotify
      den.aspects.terminal
      den.aspects.video-player

      # include workstation-only sub-aspects
      den.aspects.bluetooth._.for-workstation
      den.aspects.editor._.for-workstation
      den.aspects.network._.for-workstation
      # den.aspects.virtualisation._.waydroid
    ];

    nixos = { pkgs, ... }: {
      programs.dconf.enable = true;
      programs.partition-manager.enable = true;
    };
  };
}
