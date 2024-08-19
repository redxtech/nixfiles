{
  backup = import ./backup.nix;
  base = import ./base;
  dashy = import ./dashy.nix;
  desktop = import ./desktop;
  monitoring = import ./monitoring;
  nas = import ./nas.nix;
}
