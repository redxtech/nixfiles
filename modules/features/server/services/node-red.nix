{ self, ... }:

{
  den.aspects.node-red.settings.secretsFile = self.lib.server.mkSecretsFileOption "Node-RED";

  den.aspects.node-red.nixos =
    {
      config,
      host,
      pkgs,
      ...
    }:
    {
      network.services.node-red = config.services.node-red.port;

      services.node-red = {
        enable = true;
        withNpmAndGcc = true;
        configFile = config.sops.secrets.node-red.path;
      };

      systemd.services.node-red.path = with pkgs; [
        bash
        git
        nodejs
      ];

      sops.secrets.node-red = {
        sopsFile = host.settings.node-red.secretsFile;
        mode = "0440";
        group = config.users.users.node-red.group;
      };
    };
}
