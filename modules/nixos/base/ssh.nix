{ lib, config, ... }:

let
  inherit (lib) mkIf mkDefault;
  inherit (builtins) map listToAttrs;
  cfg = config.base;
in {
  # options.base = { };

  config = let
    inherit (config.networking) hostName;
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
      knownHosts = listToAttrs (map (name: {
        inherit name;
        value = {
          publicKeyFile = pubKey name;
          extraHostNames = (lib.optional (name == hostName) "localhost");
        };
      }) [ "bastion" "voyager" "quasar" ]);

      startAgent = true;
    };
  };
}
