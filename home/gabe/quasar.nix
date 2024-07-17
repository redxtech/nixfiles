{ pkgs, lib, config, ... }:

{
  imports = [ ./global ];

  cli.enable = true;

  desktop.monitors = [ ];

  home.packages = with pkgs; [ moonlight-qt ];
}
