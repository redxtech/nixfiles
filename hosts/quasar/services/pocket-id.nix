{ config, ... }:

let cfg = config.nas;
in {
  network.services.id = cfg.ports.pocket-id;

  services.pocket-id = {
    enable = true;

    environmentFile = config.sops.secrets."pocket_id_env".path;

    settings = {
      APP_URL = "https://id.${config.network.address}";
      TRUST_PROXY = true;
      KEYS_STORAGE = "database";
      PORT = cfg.ports.pocket-id;

      EMAIL_LOGIN_NOTIFICATION_ENABLED = true;
      EMAIL_ONE_TIME_ACCESS_AS_ADMIN_ENABLED = true;
      EMAIL_API_KEY_EXPIRATION_ENABLED = true;

      METRICS_ENABLED = true;
    };
  };

  sops.secrets."pocket_id_env" = {
    sopsFile = ../../../hosts/quasar/secrets.yaml;
    group = config.services.pocket-id.group;
    mode = "440";
  };
}
