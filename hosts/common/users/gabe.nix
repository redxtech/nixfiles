{ pkgs, config, ... }:

let
  inherit (builtins) filter hasAttr readFile;
  ifTheyExist = groups:
    filter (group: hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = false;
  users.users.gabe = {
    description = "Gabe Dunn";
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.gabe-pw.path;
    shell = pkgs.fish;
    extraGroups = [ "wheel" "video" "audio" ] ++ ifTheyExist [
      "data"
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

    openssh.authorizedKeys.keys = [ (readFile ../../../home/gabe/ssh.pub) ];

    packages = with pkgs; [
      home-manager

      discord
      feh
      firefox-devedition-bin
      flameshot
      kitty
      libsForQt5.kleopatra
      mozillavpn
      mpv
      networkmanagerapplet
      obsidian
      vscodium
    ];
  };

  sops.secrets.gabe-pw.neededForUsers = true;

  home-manager.users.gabe =
    import ../../../home/gabe/${config.networking.hostName}.nix;
}
