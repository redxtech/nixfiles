{ config, lib, pkgs, ... }:

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
      "hass"
      "input"
      "libvirtd"
      "network"
      "networkmanager"
      "podman"
      "plugdev"
      "wireshark"
    ];

    openssh.authorizedKeys.keys = [
      (readFile ../../../home/gabe/keys/gpg.pub)
      (readFile ../../../home/gabe/keys/ssh.pub)
    ];
  };

  base.yubiauth = {
    enable = lib.mkDefault true;

    mappings = [
      "gabe:MW9BvJEnapPkyE/UOpnT0skNdNyiTW/zk+ys+NJQIpcS9Ej7rHDL2AOdf8Wb/jYHAC9DSLRqf8SRbpjbW/I8wA==,6D2e7W3byi0MYF4CUfCjMwKTv0JVNL1izKYeKNOpzLlyEG4sKNfmqZWaS+9bfV6A+OlMbCT5g8v++D7nwnkNXg==,es256,+presence:MKn57WF5JlA9mSEhOEqJLJH2LMVS4wb44sR3Q8V/7D2H1xGuBuEMOc5pthRWC+5yN3URP1Ticw/o7bPWpOva0g==,CC6Ber5JNcC0I7IwXyL87reTvfZqZ+FVZQaiizTNS+g7QtxOeh6aDV/ztOoeRkS+wallUlKK9J3u4nco114fjw==,es256,+presence"
    ];
  };

  sops.secrets.gabe-pw.neededForUsers = true;

  home-manager.users.gabe =
    import ../../../home/gabe/${config.networking.hostName}.nix;
}
