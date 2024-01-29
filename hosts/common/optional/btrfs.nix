{ pkgs, lib, ... }:

{
  boot.supportedFilesystems = [ "btrfs" ];

  services.btrfs = { autoScrub.enable = true; };

  environment.systemPackages = with pkgs; [ btrfs-progs ];
}
