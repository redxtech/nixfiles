{ config, lib, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    xdg.mimeApps = let
      vivaldiDesktop = "vivaldi.desktop";
      firefox = "firefox-developer-edition.desktop";
    in {
      enable = true;

      associations.added = {
        "image/jpeg" = [ "feh.desktop" "org.gnome.gThumb.desktop" ];
        "image/png" = [ "feh.desktop" "org.gnome.gThumb.desktop" ];
        "image/gif" = [ "feh.desktop" ];
        "image/svg+xml" = [
          "feh.desktop"
          "nvim.desktop"
          "sublime_text.desktop"
          firefox
          vivaldiDesktop
        ];
        "application/xml" = [ "nvim.desktop" "sublime_text.desktop" ];
        "text/plain" = [ "nvim.desktop" "sublime_text.desktop" ];
        "text/html" =
          [ firefox vivaldiDesktop "nvim.desktop" "sublime_text.desktop" ];
        "application/javascript" = [ "nvim.desktop" "sublime_text.desktop" ];
        "application/json" = [
          "org.gnome.TextEditor.desktop"
          "sublime_text.desktop"
          "nvim.desktop"
        ];
        "application/x-raw-disk-image" = [ "7zFM.desktop" ];
        "application/octet-stream" = [ "nvim.desktop" "sublime_text.desktop" ];
        "application/toml" = [ "nvim.desktop" "sublime_text.desktop" ];
        "application/pdf" = [ "zathura.desktop" firefox ];
        "application/x-shellscript" =
          [ "nvim.desktop" "kitty-open.desktop" "sublime_text.desktop" ];
        "application/x-gnome-saved-search" =
          [ "thunar.desktop" "nemo.desktop" ];
        "application/zip" = [ "peazip.desktop" ];
        "inode/directory" = [ "thunar.desktop" "nemo.desktop" ];
        "audio/ogg" = [ "mpv.desktop" "vlc.desktop" ];
        "video/mp4" = [ "mpv.desktop" "vlc.desktop" ];
      };
      defaultApplications = {
        "inode/directory" = [ "nemo.desktop" ];
        "image/jpeg" = [ "imv-dir.desktop" ];
        "image/png" = [ "imv-dir.desktop" ];
        "text/plain" = [ "nvim.desktop" ];
        "application/json" = [ "nvim.desktop" ];
        "application/pdf" = [ "zathura.desktop" ];
        "application/x-gnome-saved-search" = [ "nemo.desktop" ];
        "video/mp4" = [ "mpv.desktop" ];
        "x-scheme-handler/postman" = [ "Postman.desktop" ];
        "x-scheme-handler/anytype" = [ "anytype.desktop" ];
      };
    };
  };
}
