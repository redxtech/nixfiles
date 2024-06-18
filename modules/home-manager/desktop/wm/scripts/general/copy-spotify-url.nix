{ writeShellApplication, coreutils, wl-clipboard, playerctl, ripgrep, choose
, ... }:

writeShellApplication {
  name = "copy-spotify-url";

  runtimeInputs = [ coreutils wl-clipboard playerctl ripgrep choose ];
  text = ''
    main() {
    	local player="''${1:-spotify}"

    	playerctl --player="$player" metadata |
    		rg 'xesam:url' |
    		choose 2 |
    		tr -d '\n' |
    		wl-copy
    }

    main "$@"
  '';
}
