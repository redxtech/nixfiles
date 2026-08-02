{
  den.aspects.default-apps.homeManager = {
    xdg.mimeApps =
      let
        firefox = "firefox-nightly.desktop";
        images = [
          "qimgv.desktop"
          "feh.desktop"
          "org.gnome.gThumb.desktop"
        ];
        videos = [
          "mpv.desktop"
          "vlc.desktop"
        ];
      in
      {
        enable = true;

        associations.added = {
          "image/jpeg" = images;
          "image/png" = images;
          "image/gif" = images;
          "image/webp" = images;
          "image/svg+xml" = images ++ [
            "neovim.desktop"
            "sublime_text.desktop"
            firefox
          ];
          "application/xml" = [
            "neovim.desktop"
            "sublime_text.desktop"
          ];
          "text/plain" = [
            "neovim.desktop"
            "sublime_text.desktop"
          ];
          "text/html" = [
            firefox
            "neovim.desktop"
            "sublime_text.desktop"
          ];
          "application/javascript" = [
            "neovim.desktop"
            "sublime_text.desktop"
          ];
          "application/json" = [
            "neovim.desktop"
            "org.gnome.TextEditor.desktop"
            "sublime_text.desktop"
          ];
          "application/x-raw-disk-image" = [ "7zFM.desktop" ];
          "application/octet-stream" = [
            "neovim.desktop"
            "sublime_text.desktop"
          ];
          "application/toml" = [
            "neovim.desktop"
            "sublime_text.desktop"
          ];
          "application/pdf" = [
            "zathura.desktop"
            firefox
          ];
          "application/x-shellscript" = [
            "neovim.desktop"
            "kitty-open.desktop"
            "sublime_text.desktop"
          ];
          "application/x-gnome-saved-search" = [
            "nemo.desktop"
            "thunar.desktop"
          ];
          "application/zip" = [
            "peazip.desktop"
            "okular.desktop"
            # "qcomicbook.desktop"
          ];
          "inode/directory" = [
            "nemo.desktop"
            "thunar.desktop"
            "ranger.desktop"
          ];
          "audio/ogg" = [
            "mpv.desktop"
            "vlc.desktop"
          ];
          "video/mp4" = videos;
          "video/webm" = videos;
          "video/x-matroska" = videos;
        };

        defaultApplications =
          let
            image = [ "qimgv.desktop" ];
            video = [ "mpv.desktop" ];
          in
          {
            "inode/directory" = [ "nemo.desktop" ];
            "image/jpeg" = image;
            "image/png" = image;
            "image/gif" = image;
            "text/plain" = [ "neovim.desktop" ];
            "application/json" = [ "neovim.desktop" ];
            "application/pdf" = [ "zathura.desktop" ];
            "application/x-gnome-saved-search" = [ "nemo.desktop" ];
            "video/mp4" = video;
            "video/webm" = video;
            "video/x-matroska" = video;
            "x-scheme-handler/postman" = [ "Postman.desktop" ];
            "x-scheme-handler/anytype" = [ "anytype.desktop" ];
          };
      };
  };
}
