{ inputs, lib, config, ... }:

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ /home/gabe/.ssh/id_ed25519 ];

    secrets = {
      bw = { path = "${config.xdg.configHome}/secrets/bw.txt"; };
      youtube = { path = "${config.xdg.configHome}/secrets/youtube.txt"; };
      openweathermap = {
        path = "${config.xdg.configHome}/secrets/openweathermap.txt";
      };
    };
  };
}
