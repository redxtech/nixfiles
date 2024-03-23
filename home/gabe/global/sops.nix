{ lib, config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = lib.mkDefault [ "/home/gabe/.ssh/id_ed25519" ];

    secrets = {
      bw = { path = "${config.xdg.configHome}/secrets/bw.txt"; };
      youtube = { path = "${config.xdg.configHome}/secrets/youtube.txt"; };
      openweathermap = {
        path = "${config.xdg.configHome}/secrets/openweathermap.txt";
      };
      "adguardian.fish" = {
        path = "${config.xdg.configHome}/secrets/adguardian.fish";
      };
    };
  };
}
