{ inputs, outputs, pkgs, lib, config, ... }:

{
  imports = [
    ./global

    ./features/desktop/gnome
  ];

  home.homeDirectory = "/var/home/${config.home.username}";
  sops.age.sshKeyPaths = [ /var/home/gabe/.ssh/id_ed25519 ];
}
