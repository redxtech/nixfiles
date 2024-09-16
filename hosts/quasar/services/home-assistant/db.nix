{ config, lib, ... }:

let
  cfg = config.nas;
  cfgNet = config.network;
in {
  config = lib.mkIf cfg.enable {
    network.services.influx = 8086;

    services.influxdb2 = {
      enable = true;

      provision = {
        enable = true;

        initialSetup = {
          username = "admin";
          organization = "main";
          bucket = "main";
          tokenFile = config.sops.secrets.influx_main_token.path;
          passwordFile = config.sops.secrets.influx_main_password.path;
        };

        organizations.home-assistant = {
          description = "Home Assistant";
          buckets.default.description = "Default bucket for Home Assistant";
          auths = {
            default = {
              description = "Home Assistant access token";
              tokenFile = config.sops.secrets.influx_homeassistant_token.path;
              allAccess = true;
            };
            grafana = {
              description = "Grafana access token";
              tokenFile = config.sops.secrets.influx_grafana_token.path;
              readBuckets = [ "default" ];
            };
          };
        };
      };
    };

    services.home-assistant.config.influxdb = {
      api_version = 2;
      host = "influx.${cfgNet.address}";
      port = 443;
      organization = "home-assistant";
      bucket = "default";
      token = "!secret influx_token";
      tags.source = "HA";
      tags_attributes = [ "friendly_name" ];
      default_measurement = "units";
      include = {
        domains = [ "binary_sensor" "sensor" "sun" ];
        entities = [ "weather.beach_house" ];
      };
      exclude = {
        entities = [ "zone.home" ];
        domains = [ "persistent_notification" "person" ];
      };
    };

    sops.secrets = let
      influxSecret = {
        sopsFile = ../../../../hosts/quasar/secrets.yaml;
        mode = "0440";
        group = config.users.users.influxdb2.group;
      };
    in {
      influx_main_password = influxSecret;
      influx_main_token = influxSecret;
      influx_homeassistant_token = influxSecret;
      influx_grafana_token = influxSecret;
    };
  };
}
