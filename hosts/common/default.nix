{ config, pkgs, ... }:

{
  imports = [
    # import users
    ./users/gabe.nix
    ./users/root.nix
  ];

  base.tz = "America/Edmonton";

  # sops
  sops.defaultSopsFile = ./secrets.yaml;
}
