{ inputs, lib, config, ... }:

{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = [ /home/gabe/.ssh/id_ed25519 ];

    secrets = {
      bw = { path = "${config.xdg.configHome}/zsh/bw.txt"; };
      youtube = { path = "${config.xdg.configHome}/rofi/youtube.txt"; };
      openweathermap = {
        path = "${config.xdg.configHome}/polybar/openweathermap.txt";
      };
    };
  };
}
