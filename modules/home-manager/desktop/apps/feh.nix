{ config, lib, pkgs, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    programs.feh.enable = true;

    xdg.desktopEntries."feh" = {
      name = "feh";
      genericName = "Image Viewer";
      comment = "Image viewer and cataloguer";
      icon = "feh";
      exec =
        "${config.programs.feh.package}/bin/feh --scale-down --auto-zoom --draw-filename --start-at %u";
      type = "Application";
      categories = [ "Graphics" "2DGraphics" "Viewer" ];
      mimeType = [
        "image/bmp"
        "image/gif"
        "image/jpeg"
        "image/jpg"
        "image/pjpeg"
        "image/png"
        "image/tiff"
        "image/webp"
        "image/x-bmp"
        "image/x-pcx"
        "image/x-png"
        "image/x-portable-anymap"
        "image/x-portable-bitmap"
        "image/x-portable-graymap"
        "image/x-portable-pixmap"
        "image/x-tga"
        "image/x-xbitmap"
      ];
    };
  };
}
