{
  den.aspects.zigbee2mqtt.nixos =
    {
      config,
      host,
      lib,
      ...
    }:
    {
      network.services.z2m = config.services.zigbee2mqtt.settings.frontend.port;

      services.zigbee2mqtt = {
        enable = true;
        dataDir = "${host.settings.server.configRoot}/zigbee2mqtt";
        settings = {
          frontend.port = 7800;
          serial.port = "/dev/ttyUSB0"; # TODO: use a /dev/serial/by-id path
          permit_join = false;
          homeassistant = lib.mkForce config.services.home-assistant.enable;
          advanced.network_key = "!secrets.yaml network_key";
          devices = "devices.yaml";
          groups = "groups.yaml";
          mqtt = {
            base_topic = "zigbee2mqtt";
            server = "mqtt://mqtt.${config.networking.fqdn}";
            user = "!secrets.yaml user";
            password = "!secrets.yaml password";
          };
        };
      };

      sops.secrets.zigbee2mqtt_secrets = {
        sopsFile = ../../../../secrets/hosts/quasar/home-assistant.yaml;
        mode = "0440";
        group = config.users.users.zigbee2mqtt.group;
        path = "${config.services.zigbee2mqtt.dataDir}/secrets.yaml";
      };
    };
}
