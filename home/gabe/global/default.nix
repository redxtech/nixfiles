{ inputs, lib, pkgs, config, ... }:

let inherit (inputs.nix-colors) colorSchemes;
in {
  imports = [
    inputs.nix-colors.homeManagerModules.default

    ./langs.nix
    ./nix.nix
    ./sops.nix
    ./user-theme.nix # TODO: remove in favour of custom theme module
    ../features/cli
    # ../features/nvim
    ../features/helix
  ];

  systemd.user.startServices = "sd-switch";

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home = {
    username = lib.mkDefault "gabe";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "23.11";
    sessionPath = [ "$HOME/.local/bin" ];
    sessionVariables = { FLAKE = "$HOME/Code/nixfiles"; };
    language.base = "en_CA.UTF-8";
  };

  colorscheme = lib.mkDefault colorSchemes.dracula;
  home.file.".colorscheme".text = config.colorscheme.slug;

  manual = {
    html.enable = true;
    json.enable = lib.mkDefault true;
  };

  # set up later
  accounts = { };
}
