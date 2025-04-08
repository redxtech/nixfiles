{ config, lib, pkgs, ... }:

let
  cfg = config.nas;
  mkConf = name: cfg.paths.config + "/" + name;
in {
  imports = [
    ./components.nix
    ./db.nix
    ./esphome.nix
    ./music-assistant.nix
    ./node-red.nix
    ./zigbee.nix
  ];

  config = lib.mkIf cfg.enable {
    network.services.ha = 8123;

    services.home-assistant = {
      enable = true;

      configDir = mkConf "homeassistant";
      lovelaceConfigWritable = true;
      openFirewall = true;

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

        sensor = let
          mkBLE = name: id: {
            name = "${name} BLE";
            platform = "mqtt_room";
            device_id = "!secret espresense_${id}";
            state_topic = "!secret espresense_${id}_topic";
            timeout = 60;
          };
        in [
          (mkBLE "Gabe's Phone" "gabe_phone")
          (mkBLE "Gabe's Watch" "gabe_watch")
          (mkBLE "Cam's Phone" "cam_phone")
          (mkBLE "Kira's Phone" "kira_phone")
          # (mkBLE "Marc's Phone" "marc_phone")
          # (mkBLE "Keir's Phone" "keir_phone")
        ];

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

        device_tracker = [{
          platform = "unifi_direct";
          host = "192.168.1.1";
          username = "!secret unifi_user";
          password = "!secret unifi_pass";
        }];

        shell_command = let
          hass-home = config.services.home-assistant.configDir;
          notify-bastion = pkgs.writeShellScript "notify-bastion" ''
            ${pkgs.openssh}/bin/ssh -i ${hass-home}/.ssh/id_ed25519 gabe@bastion "notify-send '$1' '$2' --icon home --app-name 'Home Assistant'"
          '';
        in {
          notify_bastion = ''${notify-bastion} "{{ title }}" "{{ message }}"'';
        };

        spotcast = {
          country = "CA";
          sp_dc = "!secret spotcast_gabe_sp_dc";
          sp_key = "!secret spotcast_gabe_sp_key";
        };

        var = let
          mkSpotifyDevice = id: name: icon: {
            friendly_name = "Spotify - ${name}";
            initial_value = "!secret spotify_${id}_id";
            entity_picture = "mdi:${icon}";
            unique_id = "var_spotify_device_${id}_id";
          };
          mkSpotifyPlaylist = id: name: uri: {
            friendly_name = "Spotify Playlist - ${name}";
            initial_value = "spotify:playlist:${uri}";
            entity_picture = "mdi:playlist-music";
            unique_id = "var_spotify_playlist_${id}_uri";
          };
        in {
          spt_bastion = mkSpotifyDevice "bastion" "Bastion" "desktop-classic";
          spt_gabes_phone =
            mkSpotifyDevice "gabes_phone" "Gabe's Phone" "cellphone";
          spt_bedroom_speaker =
            mkSpotifyDevice "bedroom_speaker" "Bedroom Speaker" "cast-audio";
          spt_kitchen_speaker =
            mkSpotifyDevice "kitchen_speaker" "Kitchen Speaker" "cast-audio";
          spt_living_room_tv =
            mkSpotifyDevice "living_room_tv" "Living Room TV" "television-box";
          spt_pl_censorship = mkSpotifyPlaylist "censorship" "Censorship"
            "1SEjsahPsn1pEGgyJ6mInM";
          spt_pl_masterlist = mkSpotifyPlaylist "masterlist" "The Master List"
            "33cMTnKfvqpaDFB38ZKQb4";
          spt_pl_dope =
            mkSpotifyPlaylist "dope" "Dope, I Mean" "29nSH89xCUvByNnMujjZZw";
        };

        frontend.extra_module_url =
          [ "/local/nixos-lovelace-modules/card-mod.js" ];

        automation = "!include automations.yaml";
        scene = "!include scenes.yaml";
        script = "!include scripts.yaml";
      };

      extraPackages = python3Packages: [
        python3Packages.psycopg2
        pkgs.python-unifi-ap
      ];

      customComponents = (with pkgs.home-assistant-custom-components; [
        better_thermostat
        prometheus_sensor
        localtuya
        # tuya_local
        spook
        waste_collection_schedule
      ]) ++ (with pkgs; [
        home-assistant-bermuda
        home-assistant-browser-mod
        # home-assistant-dwains-dashboard # NOTE: re-enable when issue #829 is fixed
        (home-assistant-mail-and-packages.override {
          customConfigDir = "${cfg.paths.config}/homeassistant";
        })
        home-assistant-node-red
        home-assistant-pirate-weather
        home-assistant-spotcast
        home-assistant-tuya_local
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
          home-assistant-lovelace-card-tools
          # home-assistant-lovelace-config-template-card
          home-assistant-lovelace-custom-brand-icons
          home-assistant-lovelace-ha-firemote
          home-assistant-lovelace-horizon-card
          # home-assistant-lovelace-layout-card
          home-assistant-lovelace-waze-travel-time
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

    services.wyoming.openwakeword = {
      enable = true;
      package = pkgs.wyoming-openwakeword.override {
        python3Packages = pkgs.python311Packages;
      };
    };

    sops.secrets."homeassistant_secrets.yaml" = {
      sopsFile = ../../../../hosts/quasar/secrets.yaml;
      path = "${config.services.home-assistant.configDir}/secrets.yaml";
      group = config.users.users.hass.group;
      mode = "0440";
    };
  };
}
