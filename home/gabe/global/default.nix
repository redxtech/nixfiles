{ inputs, lib, pkgs, config, outputs, ... }:

let
  inherit (inputs.nix-colors) colorSchemes;
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; })
    colorschemeFromPicture nixWallpaperFromScheme;
in {
  imports = [
    inputs.nix-colors.homeManagerModule
    inputs.nix-flatpak.homeManagerModule.nix-flatpak
    # inputs.sops-nix.homeManagerModules.sops

    ./nix.nix
    ./sops.nix
    ./user-theme.nix # TODO: remove
    ../features/cli
    # ../features/nvim
    ../features/helix
  ] ++ (builtins.attrValues outputs.homeManagerModules);

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
    sessionVariables = {
      FLAKE = "$HOME/Code/nixfiles";
    };
    language.base = "en_CA.UTF-8";
  };

  manual = {
    html.enable = true;
    json.enable = lib.mkDefault true;
  };

  # set up later
  accounts = { };

  colorscheme = lib.mkDefault colorSchemes.dracula;
  wallpaper = let
    largest = f: xs: builtins.head (builtins.sort (a: b: a > b) (map f xs));
    largestWidth = largest (x: x.width) config.monitors;
    largestHeight = largest (x: x.height) config.monitors;
  in lib.mkDefault (nixWallpaperFromScheme {
    scheme = config.colorscheme;
    width = largestWidth;
    height = largestHeight;
    logoScale = 4;
  });
  home.file.".colorscheme".text = config.colorscheme.slug;
}
