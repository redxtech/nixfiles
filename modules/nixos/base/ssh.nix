{ outputs, lib, config, ... }:

let
  cfg = config.base;
  inherit (lib) mkIf mkDefault;
in {
  # options.base = { };

  config = let
    inherit (config.networking) hostName;
    realHosts = builtins.removeAttrs outputs.nixosConfigurations [ "nixiso" ];
    pubKey = host: ../../../hosts/${host}/ssh_host_ed25519_key.pub;
  in mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
        StreamLocalBindUnlink = "yes"; # automatically remove stale sockets
        GatewayPorts = "clientspecified"; # allow forwarding ports to everywhere
        X11Forwarding = true;
      };

      hostKeys = [
        {
          path = "/etc/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          openSSHFormat = true;
          path = "/etc/ssh/ssh_host_rsa_key";
          type = "rsa";
        }
      ];
    };

    services.fail2ban.enable = mkDefault true;

    programs.ssh = {
      # each hosts public key
      knownHosts = builtins.mapAttrs (name: _: {
        publicKeyFile = pubKey name;
        extraHostNames = (lib.optional (name == hostName) "localhost");
      }) realHosts;

      startAgent = true;
    };
  };
}
