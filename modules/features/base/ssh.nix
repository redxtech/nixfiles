{ self, lib, ... }:

{
  den.aspects.ssh = {
    nixos =
      { config, ... }:
      let
        inherit (builtins)
          attrNames
          filter
          listToAttrs
          map
          pathExists
          ;
        inherit (lib) mkDefault optional;
        inherit (config.networking) hostName;

        publicKey = name: ../../hosts/${name}/ssh_host_ed25519_key.pub;
        hostNames = filter (name: pathExists (publicKey name)) (attrNames self.nixosConfigurations);

        mkFqdn =
          name:
          let
            domain = self.nixosConfigurations.${name}.config.networking.domain;
          in
          "${name}.${domain}";

        # TODO: pull from network/tailscale module
        tailnet = "colobus-pirate.ts.net";
      in
      {
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = false;
            PermitRootLogin = "prohibit-password";
            StreamLocalBindUnlink = "yes";
            GatewayPorts = "clientspecified";
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

        services.fail2ban = {
          enable = mkDefault true;
          maxretry = 5;
          ignoreIP = [
            # TODO: pull from network module
            "100.127.248.117" # bastion
            "100.107.238.120" # voyager
          ];
        };

        programs.ssh = {
          knownHosts = listToAttrs (
            map (name: {
              inherit name;
              value = {
                publicKeyFile = publicKey name;
                extraHostNames = [
                  (mkFqdn name)
                  "${name}.${tailnet}"
                ]
                ++ optional (name == hostName) "localhost";
              };
            }) hostNames
          );

          startAgent = false;
        };
      };

    homeManager = { user, lib, ... }: {
      programs.ssh =
        let
          username = user.userName;
          identityFile = "~/.ssh/id_rsa_yubikey.pub";
          identityFiles = [
            identityFile
            "~/.ssh/id_ed25519"
          ];
          # TODO: fix gpg-agent forwarding
          # remoteForwards = [
          #   {
          #     bind.address = "/run/user/%i/gnupg/S.gpg-agent";
          #     host.address = "/run/user/%i/gnupg/S.gpg-agent.extra";
          #   }
          # ];

          mkHost =
            args:
            {
              IdentityFile = identityFile;
              User = username;
              IdentitiesOnly = true;
            }
            // args;

          mkDevice =
            name:
            mkHost {
              # RemoteForward = remoteForwards;
              IdentityFile = identityFiles;
              HostName = "${name}.colobus-pirate.ts.net";
              # HostName = "${name}.sucha.foo"; # TODO: maybe?
              ForwardAgent = true;
            };
        in
        {
          enable = true;
          enableDefaultConfig = false;

          settings = {
            bastion = mkDevice "bastion";
            voyager = mkDevice "voyager";
            quasar = mkDevice "quasar";
            homeassistant = mkHost {
              User = "hassio";
              HostName = "homeassistant";
            };
            sb = mkHost {
              User = "redxtech";
              HostName = "titan.usbx.me";
            };
            rsync = mkHost {
              User = "fm1620";
              HostName = "fm1620.rsync.net";
            };

            "aur.archlinux.org" = mkHost {
              User = "aur";
              IdentityFile = "~/.ssh/aur.pub";
            };
            "github.com" = mkHost {
              IdentityFile = identityFiles;
            };

            "*" =
              lib.hm.dag.entryAfter
                [
                  "aur.archlinux.org"
                  "bastion"
                  "github.com"
                  "homeassistant"
                  "quasar"
                  "rsync"
                  "sb"
                  "voyager"
                ]
                {
                  ForwardAgent = false;
                  AddKeysToAgent = "no";
                  Compression = false;
                  ServerAliveInterval = 0;
                  ServerAliveCountMax = 3;
                  HashKnownHosts = false;
                  UserKnownHostsFile = "~/.ssh/known_hosts";
                  ControlMaster = "no";
                  ControlPath = "~/.ssh/master-%r@%n:%p";
                  ControlPersist = "no";
                };
          };
        };

      home.file = {
        ".ssh/id_rsa_yubikey.pub".source = ../../users/gabe/gpg.pub;
        ".ssh/id_ed25519.pub".source = ../../users/gabe/ssh.pub;
      };
    };
  };
}
