{ writeShellApplication, kitty, fish, ps_mem, ... }:

writeShellApplication {
  name = "ps_mem";

  runtimeInputs = [ kitty fish ps_mem ];
  text = ''
    kitty --single-instance --class kitty_float fish -c 'sudo ps_mem; read -s -n 1 -p "echo Press any key to continue..."'
  '';
}
