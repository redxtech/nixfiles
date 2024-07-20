{
  base = import ./base.nix;
  cli = import ./cli;
  desktop = import ./desktop;
  fonts = import ./fonts.nix;
  gammarelay = import ./gammarelay.nix;
  mopidy = import ./mopidy.nix;
  neo-lsp = import ./neo-lsp.nix;
  snapcast = import ./snapcast.nix;
  user-theme = import ./user-theme.nix;
  zinit = import ./zinit.nix;
}
