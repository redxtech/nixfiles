{ writeShellApplication, writeShellScriptBin, hdrop, kitty, btop, ... }:

let
  runKitty = writeShellScriptBin "run-kitty" ''
    ${kitty}/bin/kitty --single-instance --class kitty_btop btop
  '';
in writeShellApplication {
  name = "hdrop-btop";

  runtimeInputs = [ hdrop kitty btop ];
  text = ''
    hdrop -c kitty_btop ${runKitty}/bin/run-kitty
  '';
}
