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

        spotcast = {
          country = "CA";
          sp_dc = "!secret spotcast_gabe_sp_dc";
          sp_key = "!secret spotcast_gabe_sp_key";
        };

        var = {
          spt_bastion = {
            friendly_name = "Spotify - Bastion";
            initial_value = "!secret spotify_bastion_id";
            entity_picture = "mdi:desktop-classic";
            unique_id = "var_spotify_device_bastion_id";
          };
          spt_gabes_phone = {
            friendly_name = "Spotify - Gabe's Phone";
            initial_value = "!secret spotify_gabes_phone_id";
            entity_picture = "mdi:cellphone";
            unique_id = "var_spotify_device_gabes_phone_id";
          };
          spt_bedroom_speaker = {
            friendly_name = "Spotify - Bedroom Speaker";
            initial_value = "!secret spotify_bedroom_speaker_id";
            entity_picture = "mdi:cast-audio";
            unique_id = "var_spotify_device_bedroom_speaker_id";
          };
          spt_kitchen_speaker = {
            friendly_name = "Spotify - Kitchen Speaker";
            initial_value = "!secret spotify_kitchen_speaker_id";
            entity_picture = "mdi:cast-audio";
            unique_id = "var_spotify_device_kitchen_speaker_id";
          };
          spt_living_room_tv = {
            friendly_name = "Spotify - Living Room TV";
            initial_value = "!secret spotify_living_room_tv_id";
            entity_picture = "mdi:television-speaker";
            unique_id = "var_spotify_device_living_room_tv_id";
          };
          spt_pl_censorship = {
            friendly_name = "Spotify Playlist - Censorship";
            initial_value =
              "spotify:playlist:1SEjsahPsn1pEGgyJ6mInM?si=194d6c996a0e4f17";
            entity_picture = "mdi:playlist-music";
            unique_id = "var_spotify_playlist_censorship_uri";
          };
          spt_pl_masterlist = {
            friendly_name = "Spotify Playlist - The Master List";
            initial_value =
              "spotify:playlist:33cMTnKfvqpaDFB38ZKQb4?si=bd1615420cd848cc";
            entity_picture = "mdi:playlist-music";
            unique_id = "var_spotify_playlist_masterlist_uri";
          };
          spt_pl_dope = {
            friendly_name = "Spotify Playlist - Dope, I Mean";
            initial_value =
              "spotify:playlist:29nSH89xCUvByNnMujjZZw?si=576717e26f9947ce";
            entity_picture = "mdi:playlist-music";
            unique_id = "var_spotify_playlist_dope_uri";
          };
        };

        automation = "!include automations.yaml";
        scene = "!include scenes.yaml";
        script = "!include scripts.yaml";
      };

      customComponents = (with pkgs.home-assistant-custom-components; [
        better_thermostat
        prometheus_sensor
        localtuya
        spook
        waste_collection_schedule
      ]) ++ (with pkgs; [
        home-assistant-grocy
        home-assistant-spotcast
        home-assistant-var
      ]);

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
