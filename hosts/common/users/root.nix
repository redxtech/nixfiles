{ pkgs, config, ... }:

{
  users.users.root = {
    hashedPasswordFile = config.sops.secrets.root-pw.path;
    shell = pkgs.fish;

    openssh.authorizedKeys.keys =
      [ (builtins.readFile ../../../home/gabe/ssh.pub) ];
  };

  sops.secrets.root-pw.neededForUsers = true;
}
