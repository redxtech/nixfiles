{ writeShellApplication, kitty, fish, curl, ... }:

writeShellApplication {
  name = "wttr";

  runtimeInputs = [ kitty fish curl ];
  text = ''
    kitty --single-instance --class kitty_float fish -c 'curl wttr.in; read -s -n 1 -p "echo Press any key to continue..."'
  '';
}
