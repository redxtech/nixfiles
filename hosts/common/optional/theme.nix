{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    catppuccin-sddm-corners
    sddm-chili-theme

    dracula-theme
    nordzy-cursor-theme
    papirus-icon-theme
    vimix-icon-theme
  ];
}
