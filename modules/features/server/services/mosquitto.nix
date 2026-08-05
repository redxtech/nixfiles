{ self, ... }:

{
  den.aspects.mosquitto.settings.secretsFile = self.lib.server.mkSecretsFileOption "Mosquitto";

  den.aspects.mosquitto.nixos =
    { config, host, ... }:
    let
      server = host.settings.server;
    in
    {
      services.mosquitto = {
        enable = true;
        dataDir = "${server.configRoot}/mosquitto";
        listeners = [
          {
            port = 1883;
            users = {
              espresense = {
                acl = [
                  "readwrite $SYS/#"
                  "readwrite espresense/#"
                  "readwrite homeassistant/#"
                ];
                passwordFile = config.sops.secrets.mosquitto_espresense_password.path;
              };
              homeassistant = {
                acl = [
                  "readwrite $SYS/#"
                  "readwrite zigbee2mqtt/#"
                  "readwrite espresense/#"
                  "readwrite homeassistant/#"
                  "readwrite hass/#"
                ];
                passwordFile = config.sops.secrets.mosquitto_homeassistant_password.path;
              };
            };
          }
        ];
      };

      networking.firewall.allowedTCPPorts = [ 1883 ];

      sops.secrets = {
        mosquitto_espresense_password.sopsFile = host.settings.mosquitto.secretsFile;
        mosquitto_homeassistant_password.sopsFile = host.settings.mosquitto.secretsFile;
      };
    };
}
