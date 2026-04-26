{ config, pkgs, ... }:

{
  imports = [ ./sops.nix ];

  base.enable = true;
  cli.enable = true;

  home.packages = with pkgs; [ moonlight-qt ];
}
