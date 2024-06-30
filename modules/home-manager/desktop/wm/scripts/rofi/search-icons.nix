{ writeShellApplication, coreutils, findutils, fd, sd, wl-clipboard
, papirus-icon-theme, tofi, rofiCmd ? "${tofi}/bin/tofi", ... }:

writeShellApplication {
  name = "search-icons";

  runtimeInputs = [ coreutils findutils fd sd wl-clipboard ];
  text = ''
    rofi_cmd () {
      ${rofiCmd} --prompt-text "$@"
    }

    main() {
      search_term="$1"
      shift

      found_icons="$(fd ".*($search_term).*" "$@" -i ${papirus-icon-theme}/share/icons/Papirus)"

      [ -z "$found_icons" ] && echo "no matching icons found" && return 1

      echo "$found_icons" |
        xargs -L1 basename |
        sd '\.svg$' "" |
        rofi_cmd "choose icon: " |
        sd "\n" "" |
        wl-copy
    }

    main "$@"
  '';
}
