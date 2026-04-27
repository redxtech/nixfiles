# aspect for the user "root"
{
  den.aspects.root.nixos =
    { config, pkgs, ... }:
    {
      users.mutableUsers = false;
      users.users.root.hashedPasswordFile = config.sops.secrets.root-pw.path;
      users.users.root.shell = pkgs.fish;
      sops.secrets.root-pw.neededForUsers = true;
    };
}
