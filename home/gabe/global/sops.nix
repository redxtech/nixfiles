{ inputs, lib, config, ... }:

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ "$HOME/.ssh/id_ed25519" ];

    secrets = {
      youtube = { path = "${config.xdg.configHome}/rofi/youtube.txt"; };
    };
  };
}
