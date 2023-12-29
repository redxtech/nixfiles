{ inputs, lib, config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ "$HOME/.ssh/id_ed25519" ];
  };
}
