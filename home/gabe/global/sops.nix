{ lib, config, ... }:

{
  sops = {
    defaultSopsFile = ../secrets.yaml;
    age.sshKeyPaths = lib.mkDefault [ "/home/gabe/.ssh/id_ed25519" ];

    secrets = {
      bw.path = "${config.xdg.configHome}/secrets/bw.txt";
      cachix.path = "${config.xdg.configHome}/secrets/cachix.txt";
      cachix-activate.path =
        "${config.xdg.configHome}/secrets/cachix-activate.txt";
      ds3_save.path = "${config.xdg.configHome}/secrets/ds3_save.txt";
      youtube.path = "${config.xdg.configHome}/secrets/youtube.txt";
      openweathermap.path =
        "${config.xdg.configHome}/secrets/openweathermap.txt";
      "adguardian.fish".path =
        "${config.xdg.configHome}/secrets/adguardian.fish";
      mopidy_auth.path = "${config.xdg.configHome}/secrets/mopidy_auth.conf";
      hass_url.path = "${config.xdg.configHome}/secrets/hass_url.txt";
      hass_token.path = "${config.xdg.configHome}/secrets/hass_token.txt";
      limbo_config.path = "${config.xdg.configHome}/limbo/secrets.json";
    };
  };
}
