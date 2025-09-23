{ config, lib, pkgs, ... }:

let
  cfg = config.nas;
  cfgNet = config.network;
in {
  config = lib.mkIf cfg.enable {
    network.services.z2m = config.services.zigbee2mqtt.settings.frontend.port;

    services.mosquitto = {
      enable = true;

      dataDir = cfg.paths.config + "/mosquitto";
      listeners = [{
        port = 1883;
        users = {
          espresense = {
            acl = [
              "readwrite $SYS/#"
              "readwrite espresense/#"
              "readwrite homeassistant/#"
            ];
            passwordFile =
              config.sops.secrets.mosquitto_espresense_password.path;
          };
          homeassistant = {
            acl = [
              "readwrite $SYS/#"
              "readwrite zigbee2mqtt/#"
              "readwrite espresense/#"
              "readwrite homeassistant/#"
              "readwrite hass/#"
            ];
            passwordFile =
              config.sops.secrets.mosquitto_homeassistant_password.path;
          };
        };
      }];
    };

    services.zigbee2mqtt = {
      enable = true;

      dataDir = cfg.paths.config + "/zigbee2mqtt";
      settings = {
        frontend.port = 7800;
        serial.port = "/dev/ttyUSB0";
        permit_join = false;

        homeassistant = lib.mkForce config.services.home-assistant.enable;
        advanced.network_key = "!secrets.yaml network_key";

        devices = "devices.yaml";
        groups = "groups.yaml";

        mqtt = {
          base_topic = "zigbee2mqtt";
          server = "mqtt://mqtt.${cfgNet.address}";
          user = "!secrets.yaml user";
          password = "!secrets.yaml password";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 1883 ];

    sops.secrets = {
      mosquitto_espresense_password.sopsFile =
        ../../../../hosts/quasar/secrets.yaml;
      mosquitto_homeassistant_password.sopsFile =
        ../../../../hosts/quasar/secrets.yaml;
      zigbee2mqtt_secrets = {
        sopsFile = ../../../../hosts/quasar/secrets.yaml;
        mode = "0440";
        group = config.users.users.zigbee2mqtt.group;
        path = config.services.zigbee2mqtt.dataDir + "/secrets.yaml";
      };
    };
  };
}
