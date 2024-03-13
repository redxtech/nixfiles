# This file (and the global directory) holds config that i use on all hosts
{ inputs, outputs, pkgs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    # ./auto-upgrade.nix
    ./cli.nix
    ./locale.nix
    ./sops.nix
    # ./systemd-initrd.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  environment.systemPackages = with pkgs; [
    # basic tools
    curl
    file
    gcc
    git
    htop
    killall
    lsb-release
    man-pages
    man-pages-posix
    neovim
    ps_mem
    unrar
    unzip
    wget
    xclip
  ];

  hardware.enableRedistributableFirmware = true;
}
