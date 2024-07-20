{ config, lib, pkgs, ... }:

{
  imports = [ ./sops.nix ];

  cli.enable = true;

  desktop.monitors = [ ];

  home.packages = with pkgs; [ moonlight-qt ];
}
