{ ... }@args:

{
  # functions to create labels for containers
  labels = import ./labels.nix args;

  # container ports
  mkPort = host: guest: "${toString host}:${toString guest}";
  mkPorts = port: "${toString port}:${toString port}";
}
