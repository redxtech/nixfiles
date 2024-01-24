{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [ logiops piper ];

  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true;

  services.ratbagd.enable = true;

  # environment.etc = { "logid.cfg" = { text = ""; }; }; # TODO: add logiops config when it supports the mx master 3s via bolt dongle
}
