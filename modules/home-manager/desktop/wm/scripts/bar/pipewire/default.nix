{ writeShellApplication, wireplumber, coreutils, ripgrep, choose, sd }:

writeShellApplication {
  name = "pipewire";
  runtimeInputs = [ wireplumber coreutils ripgrep choose sd ];

  text = builtins.readFile ./pipewire-control.sh;
}
