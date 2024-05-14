{ writeShellApplication, coreutils, home-assistant-cli, ... }:

writeShellApplication {
  name = "home-assistant";
  runtimeInputs = [ coreutils home-assistant-cli ];
  text = ''
    # shellcheck disable=SC2155
    export HASS_SERVER="$(cat "$HOME"/.config/secrets/hass_url.txt)"
    # shellcheck disable=SC2155
    export HASS_TOKEN="$(cat "$HOME"/.config/secrets/hass_token.txt)"

    LIGHT_ID="light.in_wall_600w_dimmer"
    FAN_ID="fan.bedroom_fan"

    toggle_light () {
      hass-cli service call light.toggle --arguments entity_id=$LIGHT_ID
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
