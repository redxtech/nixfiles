{
  den.aspects.esphome.nixos =
    { config, host, ... }:
    {
      network.services.esphome = config.services.esphome.port;

      services.esphome = {
        enable = true;
        address = "0.0.0.0";
        openFirewall = true;
      };

      systemd.services.esphome.serviceConfig.EnvironmentFile = config.sops.secrets.esphome_env.path;
      sops.secrets.esphome_env.sopsFile = host.settings.server.legacySopsFile;
    };
}
