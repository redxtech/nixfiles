{ pkgs, config, ... }:

{
  imports = [
    # import users
    ./users/gabe.nix
    ./users/root.nix
  ];

  # sops
  sops.defaultSopsFile = ./secrets.yaml;
}
