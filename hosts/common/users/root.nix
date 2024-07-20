{ pkgs, config, ... }:

{
  users.users.root = {
    hashedPasswordFile = config.sops.secrets.root-pw.path;
    shell = pkgs.fish;

    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../../home/gabe/keys/ssh.pub)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE1SeMUvFtcjtMbD+Kz7mGI1OSQ8ga18BflxAwzw/wLt quasar hercules-ci-agent ssh key"
    ];
  };

  sops.secrets.root-pw.neededForUsers = true;
}
