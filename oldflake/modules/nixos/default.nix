{
  backup = import ./backup.nix;
  base = import ./base;
  desktop = import ./desktop;
  hyprpolkitagent = import ./hyprpolkitagent.nix;
  monitoring = import ./monitoring;
  nas = import ./nas.nix;
  network = import ./network;
}
