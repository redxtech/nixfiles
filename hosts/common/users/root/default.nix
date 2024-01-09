{ pkgs, config, ... }:

{
  users.users.root = {
    hashedPasswordFile = config.sops.secrets.root-pw.path;
    shell = pkgs.fish;
  };

  sops.secrets.root-pw.neededForUsers = true;
}
