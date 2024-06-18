{ writeShellApplication, wl-clipboard, cliphist, tofi, ... }:

writeShellApplication {
  name = "clipboard";

  runtimeInputs = [ wl-clipboard cliphist tofi ];
  text = ''
    cliphist list |
      tofi |
      cliphist decode |
      wl-copy
  '';
}
