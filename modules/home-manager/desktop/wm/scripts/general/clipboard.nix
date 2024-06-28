{ writeShellApplication, wl-clipboard, clipman, tofi, ... }:

writeShellApplication {
  name = "clipboard";

  runtimeInputs = [ wl-clipboard clipman tofi ];
  text = ''
    clipman pick --tool CUSTOM --tool-args "tofi --width 1280 --height 720"
  '';
}
