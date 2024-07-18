{ config, lib, pkgs, stable, ... }:

let
  cfg = config.desktop;
  scripts = cfg.wm.scripts;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ cinnamon.nemo-with-extensions ];

    xdg.dataFile = let
      kitty = "${pkgs.kitty}/bin/kitty --class kitty_float";
      kittySize = "-o initial_window_width=80c -o initial_window_height=25c";
      fish = "${pkgs.fish}/bin/fish";
      clamav = "${pkgs.clamav}/bin/clamscan";
      wrapShell = cmd: "${pkgs.bash}/bin/bash -c '${cmd}'";

      # https://github.com/linuxmint/nemo/blob/master/files/usr/share/nemo/actions/sample.nemo_action
      actions = {
        clamscan = {
          name = "Clam Scan";
          description = "Clam Scan";
          exec =
            "${kitty} ${kittySize} ${fish} -c '${clamav} %F; read -n 1 -p \"echo Press any key to continue...\"'";
          icon = "bug-buddy";
          selection = "Any";
          extensions = "dir;exe;dll;zip;gz;7z;rar;";
          mimetypes = null;
          terminal = false;
        };
        convert = {
          name = "Convert Image";
          description = "Converts an image to another format with ImageMagick";
          exec = "${scripts.rofi.convert} %F";
          icon = "image";
          selection = "s";
          extensions = null;
          mimetypes = "image/*";
          terminal = false;
        };
        archive = {
          name = "Create Archive";
          description = "Creates an archive with atool";
          exec = wrapShell "${scripts.rofi.archiver} %F";
          icon = "archive";
          selection = "notnone";
          extensions = "any";
          mimetypes = null;
          terminal = false;
        };
        unpack = {
          name = "Unpack Archive";
          description = "Unpacks an archive with atool";
          exec = "${scripts.general.unarchiver} %F";
          icon = "archive-extract";
          selection = "s";
          extensions =
            "gz;tgz;bz;tbz;bz2;tbz2;Z;tZ;lzo;tzo;lz;tlz;xz;txz;7z;t7z;tar;zip;jar;war;rar;lha;lhz;alz;ace;a;arj;arc;rpm;deb;cab;lzma;rz;lrz;cpio";
          mimetypes = null;
          terminal = false;
        };
        encode = {
          name = "Encode Video";
          description = "Encodes a video with ffmpeg";
          exec = "${scripts.rofi.encoder} %F";
          icon = "video";
          selection = "s";
          extensions = null;
          mimetypes = "video/*";
          terminal = false;
        };
        mediainfo = {
          name = "Show Mediainfo";
          description = "Shows a file's mediainfo";
          exec =
            "${pkgs.fish}/bin/fish -c '${pkgs.mediainfo}/bin/mediainfo %F; read -n 1 -p \"echo Press any key to continue...\"'";
          icon = "media-video";
          selection = "s";
          extensions = null;
          mimetypes = "video/*;audio/*";
          terminal = true;
        };
      };
    in builtins.listToAttrs (lib.mapAttrsToList (name: action: {
      name = "nemo/actions/${name}.nemo_action";
      value.text = ''
        [Nemo Action]
        Name=${action.name}
        Comment=${action.description}
        Icon-Name=${action.icon}

        Exec=${action.exec}
        ${if action.terminal then "Terminal=true" else "Terminal=false"}

        Selection=${action.selection}
        ${
          if action.extensions != null then
            "Extensions=${action.extensions}"
          else
            ""
        }${
          if action.mimetypes != null then
            "Mimetypes=${action.mimetypes}"
          else
            ""
        }'';
    }) actions);

    # dconf settings
    dconf.settings = let
      kittyTerm = {
        exec = "${pkgs.kitty}/bin/kitty";
        exec-arg = "";
      };
    in {
      "org/nemo/desktop".show-desktop-icons = false;
      "org/cinnamon/desktop/default-applications/terminal" = kittyTerm;
      "org/gnome/desktop/default-applications/terminal" = kittyTerm;
      "org/cinnamon/desktop/applications/terminal" = kittyTerm;
      "org/gnome/desktop/applications/terminal" = kittyTerm;
    };
  };
}
