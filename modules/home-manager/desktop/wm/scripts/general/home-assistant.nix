{ writeShellApplication, coreutils, home-assistant-cli, ... }:

writeShellApplication {
  name = "home-assistant";
  runtimeInputs = [ coreutils home-assistant-cli ];
  excludeShellChecks = [ "SC2155" ];
  text = ''
    export HASS_SERVER="$(cat "$HOME"/.config/secrets/hass_url.txt)"
    export HASS_TOKEN="$(cat "$HOME"/.config/secrets/hass_token.txt)"

    LIGHT_ID="fan.bedroom_fan" # TODO: switch to light once installed
    FAN_ID="fan.bedroom_fan_2"

    toggle_light () {
      # hass-cli service call light.toggle --arguments entity_id=$LIGHT_ID
      hass-cli service call fan.toggle --arguments entity_id=$LIGHT_ID
    }

    toggle_fan () {
      hass-cli service call fan.toggle --arguments entity_id=$FAN_ID
    }

    main () {
      case $1 in
        light)
          toggle_light
          ;;
        fan)
          toggle_fan
          ;;
        *)
          echo "unknown comamnd: $1"
          ;;
      esac
    }

    main "$@"
  '';
}

