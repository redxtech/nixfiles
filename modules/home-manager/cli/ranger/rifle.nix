{ config, lib, pkgs, ... }:

let
  cfg = config.cli;
  prog = name:
    if config.desktop.enable then
      config.programs.${name}.package
    else
      pkgs.${name};
in {
  config = lib.mkIf cfg.enable {
    programs.ranger.rifle = [
      # web
      {
        condition = "ext x?html?, has firefox-developer-edition, X, flag f";
        command = ''firefox-developer-edition -p gabe -- "$@"'';
      }
      {
        condition = "ext x?html?, has lynx, terminal";
        command = ''lynx -- "$@"'';
      }

      # misc
      {
        condition = "mime ^text, label editor";
        command = ''''${VISUAL:-$EDITOR} -- "$@"'';
      }
      {
        condition = "mime ^text, label pager";
        command = ''$PAGER -- "$@"'';
      }
      {
        condition =
          "!mime ^text, label editor, ext xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart";
        command = ''''${VISUAL:-$EDITOR} -- "$@"'';
      }
      {
        condition =
          "!mime ^text, label pager, ext xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart";
        command = ''$PAGER -- "$@"'';
      }
      {
        condition = "ext 1";
        command = ''man "$1"'';
      }
      {
        condition = "ext exe, has wine";
        command = ''wine "$1"'';
      }
      {
        condition = "name ^[mM]akefile$";
        command = "make";
      }

      # scripts
      {
        condition = "ext py";
        command = ''${pkgs.python3}/bin/python3 -- "$1"'';
      }
      {
        condition = "ext rb";
        command = ''${pkgs.ruby}/bin/ruby -- "$1"'';
      }
      {
        condition = "ext js";
        command = ''${pkgs.nodejs}/bin/node -- "$1"'';
      }
      {
        condition = "ext sh";
        command = ''${pkgs.dash}/bin/sh -- "$1"'';
      }

      # audio/video
      {
        # no gui
        condition = "mime ^audio/ogg$, has mpv, terminal";
        command = ''${pkgs.mpv}/bin/mpv -- "$@"'';
      }
      {
        # with gui
        condition = "mime ^video|^audio, has mpv, X, flag f";
        command = ''${pkgs.mpv}/bin/mpv -- "$@"'';
      }
      {
        # with gui
        condition = "mime ^video|^audio, has vlc, X, flag f";
        command = ''${pkgs.vlc}/bin/vlc -- "$@"'';
      }
      {
        # no gui
        condition = "mime ^video, terminal, has mpv, !X";
        command = ''${pkgs.mpv}/bin/mpv -- "$@"'';
      }

      # images
      {
        condition = "mime ^image, has qimgv, X, flag f";
        command = ''${pkgs.qimgv}/bin/qimgv -- "$@"'';
      }
      {
        condition = "mime ^image, has feh, X, flag f, !ext gif";
        command = ''${prog "feh"}/bin/feh -- "$@"'';
      }
      {
        condition = "mime ^image, has imv, X, flag f";
        command = ''${prog "imv"}/bin/imv-dir -- "$@"'';
      }

      # documents
      {
        condition = "ext pdf|docx|epub|cb[rz], has zathura, X, flag f";
        command = ''${prog "zathura"}/bin/zathura -- "$@"'';
      }
      {
        condition = "ext docx?, has catdoc, terminal";
        command = ''${pkgs.catdoc}/bin/catdoc -- "$@" | $PAGER'';
      }
      {
        condition =
          "ext pptx?|od[dfgpst]|docx?|sxc|xlsx?|xlt|xlw|gnm|gnumeric, has libreoffice, X, flag f";
        command = ''${pkgs.libreoffice}/bin/libreoffice -- "$@"'';
      }

      # archives
      {
        condition = "ext 7z, has 7z";
        command = ''${pkgs.p7zip}/bin/7z -p l "$@" | $PAGER'';
      }
      # ext ace|ar|arc|bz2?|cab|cpio|cpt|deb|dgc|dmg|gz,     has atool = atool --list --each -- "$@" | $PAGER
      # ext iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip, has atool = atool --list --each -- "$@" | $PAGER
      # ext 7z|ace|ar|arc|bz2?|cab|cpio|cpt|deb|dgc|dmg|gz,  has atool = atool --extract --each -- "$@"
      # ext iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip, has atool = atool --extract --each -- "$@"
      {
        condition =
          "ext ace|ar|arc|bz2?|cab|cpio|cpt|deb|dgc|dmg|gz, has atool";
        command = ''${pkgs.atool}/bin/atool --list --each -- "$@" | $PAGER'';
      }
      {
        condition =
          "ext iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip, has atool";
        command = ''${pkgs.atool}/bin/atool --list --each -- "$@" | $PAGER'';
      }
      {
        condition =
          "ext 7z|ace|ar|arc|bz2?|cab|cpio|cpt|deb|dgc|dmg|gz, has atool";
        command = ''${pkgs.atool}/bin/atool --extract --each -- "$@"'';
      }
      {
        condition =
          "ext iso|jar|msi|pkg|rar|shar|tar|tgz|xar|xpi|xz|zip, has atool";
        command = ''${pkgs.atool}/bin/atool --extract --each -- "$@"'';
      }

      # fonts
      {
        condition = "mine ^font, has fontforge, X, flag f";
        command = ''${pkgs.fontforge}/bin/fontforge "$@"'';
      }

      # flag t fallback terminals
      {
        condition = "mime ^ranger/x-terminal-emulator, has kitty";
        command = ''${prog "kitty"}/bin/kitty -- "$@"'';
      }
      {
        condition = "mime ^ranger/x-terminal-emulator, has foot";
        command = ''${prog "foot"}/bin/foot -- "$@"'';
      }
      {
        condition = "mime ^ranger/x-terminal-emulator, has alacritty";
        command = ''${prog "alacritty"}/bin/alacritty -- "$@"'';
      }

      # more misc
      {
        condition = "label wallpaper";
        command = ''${pkgs.swww}/bin/swww img "$@"'';
      }

      # generic
      {
        condition = "label open, has xdg-open";
        command = ''${pkgs.xdg-utils}/bin/xdg-open "$@"'';
      }
      {
        condition = "label open, has open";
        command = ''open -- "$@"'';
      }
      {
        condition =
          "!mime ^text, !ext xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart";
        command = "ask";
      }
      {
        condition =
          "label editor, !mime ^text, !ext xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart";
        command = ''''${VISUAL:-$EDITOR} -- "$@"'';
      }
      {
        condition =
          "label pager, !mime ^text, !ext xml|json|csv|tex|py|pl|rb|rs|js|sh|php|dart";
        command = ''$PAGER -- "$@"'';
      }

      # at the bottom, to avoid accidental triggers
      {
        condition = "label trash, has trashy";
        command = ''${pkgs.trashy}/bin/trashy put -- "$@"'';
      }
    ];
  };
}
