{ config, lib, pkgs, ... }:

let
  cfg = config.nas;
  mkConf = name: cfg.paths.config + "/" + name;
in {
  imports = [ ./components.nix ];

  config = lib.mkIf cfg.enable {
    network.services.ha = 8123;

    services.home-assistant = {
      enable = true;

      configDir = mkConf "homeassistant";
      lovelaceConfigWritable = true;
      openFirewall = true;

      extraPackages = python3Packages: with python3Packages; [ psycopg2 ];

      config = {
        default_config = { };
        recorder.db_url = "postgresql://@/hass";

        http = {
          use_x_forwarded_for = true;
          server_host = [ "0.0.0.0" "::1" ];
          trusted_proxies = [ "127.0.0.1" "::1" ];
        };

        notify = [{
          name = "SendGrid";
          platform = "sendgrid";
          sender = "homeassistant@sucha.foo";
          sender_name = "Home Assistant";
          recipient = "!secret sendgrid_default_recipient";
          api_key = "!secret sendgrid_api_key";
        }];

        lovelace.mode = "yaml";

        homeassistant = {
          country = "CA";
          currency = "CAD";
          name = "Beach House";
          temperature_unit = "C";
          unit_system = "metric";

          external_url = "https://ha.quasar.sucha.foo";
          internal_url = "https://ha.quasar.sucha.foo";

          latitude = "!secret latitude";
          longitude = "!secret longitude";
          elevation = "!secret elevation";

          media_dirs.media = "/pool/media";
        };

        automation = "!include automations.yaml";
        # scenes = "!include scenes.yaml";
        # scripts = "!include scripts.yaml";
      };

      customComponents = with pkgs.home-assistant-custom-components; [
        better_thermostat
        prometheus_sensor
        # tuya_local
        localtuya
        spook
        waste_collection_schedule

        pkgs.home-assistant-grocy
      ];

      customLovelaceModules =
        (with pkgs.home-assistant-custom-lovelace-modules; [
          apexcharts-card
          atomic-calendar-revive
          button-card
          card-mod
          decluttering-card
          hourly-weather
          light-entity-card
          mini-graph-card
          mini-media-player
          multiple-entity-row
          mushroom
          template-entity-row
          universal-remote-card
        ]) ++ (with pkgs; [
          home-assistant-lovelace-bubble-card
          home-assistant-lovelace-ha-firemote
        ]);
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ "hass" ];
      ensureUsers = [{
        name = "hass";
        ensureDBOwnership = true;
      }];
      identMap = ''
        hass-user   hass  hass
        local-user  gabe  hass
      '';
      authentication = ''
        local  hass  hass                trust
        local  hass  hass                trust
        local  hass  hass                trust
        host   hass  hass  samehost      trust
        host   hass  hass  bastion       scram-sha-256
      '';
    };

    sops.secrets."homeassistant_secrets.yaml" = {
      sopsFile = ../../../../hosts/quasar/secrets.yaml;
      path = "${config.services.home-assistant.configDir}/secrets.yaml";
      group = config.users.users.hass.group;
      mode = "0440";
    };
  };
}
