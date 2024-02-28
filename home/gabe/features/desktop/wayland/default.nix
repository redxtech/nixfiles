{ inputs, pkgs, ... }:

{
  imports = [ ./desktop-apps.nix ];

  home.packages = with pkgs; [ wev ];
}
