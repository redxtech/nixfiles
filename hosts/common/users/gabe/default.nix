{ pkgs, config, ... }:
let
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users.gabe = {
    description = "Gabe Dunn";
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "video" "audio" ] ++ ifTheyExist [
      "deluge"
      "docker"
      "git"
      "input"
      "libvirtd"
      "network"
      "networkmanager"
      "podman"
      "plugdev"
      "wireshark"
    ];

    openssh.authorizedKeys.keys =
      [ (builtins.readFile ../../../../home/gabe/ssh.pub) ];
    packages = [ pkgs.home-manager ];
  };

  # home-manager.users.gabe =
  #   import ../../../../home/gabe/${config.networking.hostName}.nix;

  services.geoclue2.enable = true;
  # security.pam.services = { swaylock = { }; };
}
