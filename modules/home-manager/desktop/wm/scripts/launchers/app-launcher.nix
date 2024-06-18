{ writeShellApplication, tofi, bash, ... }:

writeShellApplication {
  name = "app-launcher";

  runtimeInputs = [ tofi bash ];
  text = ''sh -c "$(tofi-drun) &"'';
}
