{
  backup = import ./backup.nix;
  base = import ./base;
  desktop = import ./desktop;
  monitoring = import ./monitoring;
  nas = import ./nas.nix;
  network = import ./network;
}
