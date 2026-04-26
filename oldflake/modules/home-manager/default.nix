{
  base = import ./base.nix;
  cli = import ./cli;
  desktop = import ./desktop;
  fonts = import ./fonts.nix;
  gammarelay = import ./gammarelay.nix;
  neovide = import ./neovide.nix;
  user-theme = import ./user-theme.nix;
}
