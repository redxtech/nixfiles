{ writeShellApplication, wl-clipboard, cliphist, fuzzel, ... }:

writeShellApplication {
  name = "clipboard";

  runtimeInputs = [ wl-clipboard cliphist fuzzel ];
  text = ''
    cliphist list | fuzzel --dmenu --with-nth=2 --prompt "copy > " --width 60 | cliphist decode | wl-copy
  '';
}
