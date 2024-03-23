{ pkgs, lib, config, ... }:

{
  imports = [
    ./global

    ./features/desktop/gnome
  ];

  home.homeDirectory = "/var/home/${config.home.username}";
  targets.genericLinux.enable = true;

  sops.age.sshKeyPaths = [ "/var/home/gabe/.ssh/id_ed25519" ];

  services.syncthing.enable = true;

  services.cachix-agent = {
    enable = true;
    name = "deck";
  };
}
