{ writeShellApplication, playerctl, ... }:

writeShellApplication {
  name = "playerctl-tail";
  runtimeInputs = [ playerctl ];
  text = builtins.readFile ./playerctl-tail.sh;
}
