{ inputs, outputs, pkgs, config, ... }:

{
  imports = [
    # import users
    ./users/gabe.nix
    ./users/root.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  # sops
  sops.defaultSopsFile = ./secrets.yaml;
}
