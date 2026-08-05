{ self, ... }:

{
  den.aspects.home-assistant.settings.secretsFile =
    self.lib.server.mkSecretsFileOption "Home Assistant";

  den.aspects.home-assistant.nixos =
    {
      config,
      host,
      pkgs,
      self',
      ...
    }:
    let
      server = host.settings.server;
      hassHome = config.services.home-assistant.configDir;
      notifyBastion = pkgs.writeShellScript "notify-bastion" ''
        ${pkgs.openssh}/bin/ssh -i ${hassHome}/.ssh/id_ed25519 gabe@bastion "notify-send '$1' '$2' --icon home --app-name 'Home Assistant'"
      '';
      mkBLE = name: id: {
        name = "${name} BLE";
        platform = "mqtt_room";
        device_id = "!secret espresense_${id}";
        state_topic = "!secret espresense_${id}_topic";
        timeout = 60;
      };
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
    in
    {
      network.services.ha = 8123;

      services.home-assistant = {
        enable = true;
        configDir = "${server.configRoot}/homeassistant";
        lovelaceConfigWritable = true;
        openFirewall = true;

        config = {
          default_config = { };
          recorder.db_url = "postgresql://@/hass";
          http = {
            use_x_forwarded_for = true;
            trusted_proxies = [
              "127.0.0.1"
              "::1"
            ];
          };
          notify = [
            {
              name = "Email";
              platform = "smtp";
              sender = "homeassistant@sucha.foo";
              sender_name = "Home Assistant";
              recipient = "!secret smtp_default_recipient";
              server = "!secret smtp_server";
              port = "!secret smtp_port";
              username = "!secret smtp_username";
              password = "!secret smtp_password";
              encryption = "tls";
            }
          ];
          sensor = [
            (mkBLE "Gabe's Phone" "gabe_phone")
            (mkBLE "Gabe's Watch" "gabe_watch")
            (mkBLE "Cam's Phone" "cam_phone")
            (mkBLE "Kira's Phone" "kira_phone")
          ];
          homeassistant = {
            country = "CA";
            currency = "CAD";
            name = "Beach House";
            temperature_unit = "C";
            unit_system = "metric";
            external_url = "https://ha.${config.networking.fqdn}";
            internal_url = "https://ha.${config.networking.fqdn}";
            latitude = "!secret latitude";
            longitude = "!secret longitude";
            elevation = "!secret elevation";
            media_dirs.media = server.mediaRoot;
          };
          device_tracker = [
            {
              platform = "unifi_direct";
              host = "192.168.1.1";
              username = "!secret unifi_user";
              password = "!secret unifi_pass";
            }
          ];
          shell_command.notify_bastion = ''${notifyBastion} "{{ title }}" "{{ message }}"'';
          spotcast = {
            country = "CA";
            sp_dc = "!secret spotcast_gabe_sp_dc";
            sp_key = "!secret spotcast_gabe_sp_key";
          };
          var = {
            spt_bastion = mkSpotifyDevice "bastion" "Bastion" "desktop-classic";
            spt_gabes_phone = mkSpotifyDevice "gabes_phone" "Gabe's Phone" "cellphone";
            spt_bedroom_speaker = mkSpotifyDevice "bedroom_speaker" "Bedroom Speaker" "cast-audio";
            spt_kitchen_speaker = mkSpotifyDevice "kitchen_speaker" "Kitchen Speaker" "cast-audio";
            spt_living_room_tv = mkSpotifyDevice "living_room_tv" "Living Room TV" "television-box";
            spt_pl_censorship = mkSpotifyPlaylist "censorship" "Censorship" "1SEjsahPsn1pEGgyJ6mInM";
            spt_pl_masterlist = mkSpotifyPlaylist "masterlist" "The Master List" "33cMTnKfvqpaDFB38ZKQb4";
            spt_pl_dope = mkSpotifyPlaylist "dope" "Dope, I Mean" "29nSH89xCUvByNnMujjZZw";
          };
          frontend.extra_module_url = [ "/local/nixos-lovelace-modules/card-mod.js" ];
          automation = "!include automations.yaml";
          scene = "!include scenes.yaml";
          script = "!include scripts.yaml";
        };

        extraComponents = [
          "accuweather"
          "adguard"
          "aftership"
          "alert"
          "alexa"
          "analytics"
          "analytics_insights"
          "androidtv"
          "androidtv_remote"
          "anthropic"
          "api"
          "apple_tv"
          "application_credentials"
          "apprise"
          "auth"
          "automation"
          "backup"
          "binary_sensor"
          "blueprint"
          "bluetooth"
          "bluetooth_adapters"
          "bluetooth_le_tracker"
          "broadlink"
          "button"
          "calendar"
          "camera"
          "cast"
          "climate"
          "cloud"
          "cloudflare"
          "command_line"
          "config"
          "configurator"
          "conversation"
          "counter"
          "cover"
          "cpuspeed"
          "date"
          "datetime"
          "default_config"
          "deluge"
          "denon"
          "denonavr"
          "device_automation"
          "device_sun_light_trigger"
          "device_tracker"
          "dhcp"
          "diagnostics"
          "discord"
          "energy"
          "epic_games_store"
          "esphome"
          "event"
          "fan"
          "ffmpeg"
          "ffmpeg_motion"
          "ffmpeg_noise"
          "file"
          "filter"
          "folder"
          "folder_watcher"
          "frontend"
          "generic"
          "geo_location"
          "google"
          "google_assistant"
          "google_assistant_sdk"
          "google_cloud"
          "google_generative_ai_conversation"
          "google_mail"
          "google_maps"
          "google_pubsub"
          "google_translate"
          "google_travel_time"
          "group"
          "habitica"
          "hardware"
          "haveibeenpwned"
          "hddtemp"
          "hdmi_cec"
          "here_travel_time"
          "history"
          "history_stats"
          "holiday"
          "homeassistant"
          "homeassistant_alerts"
          "homekit"
          "homekit_controller"
          "html5"
          "http"
          "image"
          "image_processing"
          "image_upload"
          "imap"
          "influxdb"
          "input_boolean"
          "input_button"
          "input_datetime"
          "input_number"
          "input_select"
          "input_text"
          "integration"
          "intent"
          "ios"
          "ipp"
          "isal"
          "jellyfin"
          "lastfm"
          "led_ble"
          "light"
          "local_calendar"
          "local_file"
          "local_ip"
          "local_todo"
          "lock"
          "logbook"
          "logger"
          "lovelace"
          "manual"
          "manual_mqtt"
          "media_extractor"
          "media_player"
          "media_source"
          "met"
          "min_max"
          "minecraft_server"
          "mobile_app"
          "moon"
          "mqtt"
          "mqtt_eventstream"
          "mqtt_json"
          "mqtt_room"
          "mqtt_statestream"
          "music_assistant"
          "my"
          "network"
          "nextbus"
          "notify"
          "number"
          "onboarding"
          "open_meteo"
          "openweathermap"
          "otp"
          "panel_custom"
          "persistent_notification"
          "person"
          "ping"
          "plant"
          "plex"
          "profiler"
          "prometheus"
          "proximity"
          "qrcode"
          "radarr"
          "radio_browser"
          "random"
          "recollect_waste"
          "recorder"
          "recovery_mode"
          "remote"
          "repairs"
          "rest"
          "rest_command"
          "scene"
          "schedule"
          "script"
          "ssdp"
          "search"
          "season"
          "select"
          "sensor"
          "serial"
          "seventeentrack"
          "shell_command"
          "smtp"
          "sonarr"
          "spotify"
          "statistics"
          "steam_online"
          "stream"
          "sun"
          "switch"
          "system_health"
          "system_log"
          "systemmonitor"
          "tag"
          "tailscale"
          "tautulli"
          "tcp"
          "text"
          "tile"
          "time"
          "time_date"
          "timer"
          "todo"
          "todoist"
          "trace"
          "tts"
          "tuya"
          "unifi"
          "unifi_direct"
          "universal"
          "update"
          "upnp"
          "uptime"
          "usb"
          "version"
          "wake_on_lan"
          "waze_travel_time"
          "weather"
          "webhook"
          "websocket_api"
          "whois"
          "wiz"
          "wyoming"
          "zeroconf"
          "zha"
          "zone"
        ];

        extraPackages = python3Packages: [
          python3Packages.psycopg2
          python3Packages.unifi-ap
        ];
        customComponents =
          (with pkgs.home-assistant-custom-components; [
            better_thermostat
            prometheus_sensor
            localtuya
            tuya_local
            spook
            waste_collection_schedule
          ])
          ++ (with self'.packages; [
            home-assistant-components-bermuda
            home-assistant-components-browser-mod
            home-assistant-components-iphonedetect
            home-assistant-components-node-red
            home-assistant-components-pirate-weather
            home-assistant-components-spotcast
            home-assistant-components-tuya-local
            home-assistant-components-var
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
          ])
          ++ (with self'.packages; [
            home-assistant-lovelace-bubble-card
            home-assistant-lovelace-card-tools
            home-assistant-lovelace-custom-brand-icons
            home-assistant-lovelace-ha-firemote
            home-assistant-lovelace-horizon-card
            home-assistant-lovelace-waze-travel-time
          ]);
      };

      services.postgresql = {
        enable = true;
        ensureDatabases = [ "hass" ];
        ensureUsers = [
          {
            name = "hass";
            ensureDBOwnership = true;
          }
        ];
        identMap = ''
          hass-user   hass  hass
          local-user  gabe  hass
        '';
        authentication = ''
          local  hass  hass                trust
          host   hass  hass  samehost      trust
          host   hass  hass  bastion       scram-sha-256
        '';
      };

      sops.secrets."secrets.yaml" = {
        sopsFile = host.settings.home-assistant.secretsFile;
        path = "${hassHome}/secrets.yaml";
        group = config.users.users.hass.group;
        mode = "0440";
      };
    };
}
