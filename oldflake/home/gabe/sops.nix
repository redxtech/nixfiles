{ lib, config, ... }:

{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.sshKeyPaths = lib.mkDefault [ "/home/gabe/.ssh/id_ed25519" ];

    secrets = {
      cachix.path = "${config.xdg.configHome}/secrets/cachix.txt";
      cachix-activate.path = "${config.xdg.configHome}/secrets/cachix-activate.txt";
      nix-github-token.path = "${config.xdg.configHome}/secrets/nix-github-token.txt";
      youtube.path = "${config.xdg.configHome}/secrets/youtube.txt";
      hass_url.path = "${config.xdg.configHome}/secrets/hass_url.txt";
      hass_token.path = "${config.xdg.configHome}/secrets/hass_token.txt";
      openrouter_key.path = "${config.xdg.configHome}/secrets/openrouter_key.txt";
      openai_key.path = "${config.xdg.configHome}/secrets/openai_key.txt";
    };
  };
}
