{ writeShellApplication, writeText, coreutils, wl-clipboard, xclip, fuzzel
, rofiCmd ? "${fuzzel}/bin/fuzzel", useWayland ? true, ... }:

let
  nerd-icon-list =
    writeText "nerd-icon-list" (builtins.readFile ./nerd-icons.txt);
in writeShellApplication {
  name = "nerd-icons";
  runtimeInputs = [ coreutils (if useWayland then wl-clipboard else xclip) ];

  text = ''
    # rofi script to choose an icon from the nerd-icons list
    # usage: nerd-icons

    # rofi_cmd: wrapper around rofi to set prompt text and size
    rofi_cmd () {
      prompt="$1 "
      shift
      ${rofiCmd} --dmenu --prompt "$prompt " "$@"
    }

    main () {
      rofi_cmd "Icon 󰄾" <${nerd-icon-list} \
      | awk '{print $1}' \
      | tr -d '\n' \
      | ${if useWayland then "wl-copy" else "xclip -selection clipboard"}
    }

    main
  '';
}
