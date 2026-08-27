{ self, lib, ... }:

{
  den.aspects.ssh = {
    settings.forwardDiskKey = lib.mkEnableOption "forwarding the disk-backed Ed25519 key to trusted devices";

    nixos =
      { host, config, ... }:
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
        inherit (host.settings.tailscale) tailnet;

        publicKey = name: ../../hosts/${name}/ssh_host_ed25519_key.pub;
        hostNames = filter (name: pathExists (publicKey name)) (attrNames self.nixosConfigurations);
        networkIPs = filter (ip: ip != null) (
          map (name: self.nixosConfigurations.${name}.config.network.ip) (attrNames self.nixosConfigurations)
        );
        tailnetIPs = [
          "100.127.248.117" # bastion
          "100.124.66.105" # quasar
          "100.107.238.120" # voyager
        ];

        mkFqdn =
          name:
          let
            domain = self.nixosConfigurations.${name}.config.networking.domain;
          in
          "${name}.${domain}";
      in
      {
        services.openssh = {
          enable = true;
          settings = {
            AllowAgentForwarding = true;
            GatewayPorts = "clientspecified";
            PasswordAuthentication = false;
            PermitRootLogin = "prohibit-password";
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
          ignoreIP = tailnetIPs ++ networkIPs;
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

        # mobile shell
        programs.mosh.enable = true;
      };

    homeManager =
      {
        user,
        host,
        lib,
        ...
      }:
      {
        programs.ssh =
          let
            cfg = host.settings.ssh;
            username = user.userName;
            identityFile = "~/.ssh/id_rsa_yubikey.pub";
            diskIdentityFile = "~/.ssh/id_ed25519";
            identityFiles = [
              identityFile
              diskIdentityFile
            ];
            deviceIdentityFiles =
              if cfg.forwardDiskKey then
                [
                  diskIdentityFile
                  identityFile
                ]
              else
                identityFiles;
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
              mkHost (
                {
                  IdentityFile = deviceIdentityFiles;
                  HostName = "${name}.colobus-pirate.ts.net";
                  # HostName = "${name}.sucha.foo"; # TODO: maybe?
                  ForwardAgent = true;
                }
                // lib.optionalAttrs cfg.forwardDiskKey { AddKeysToAgent = "yes"; }
              );
          in
          {
            enable = true;
            enableDefaultConfig = false;

            settings = {
              bastion = mkDevice "bastion";
              voyager = mkDevice "voyager";
              quasar = mkDevice "quasar";
              otoro = mkHost {
                User = "superlodon";
                HostName = "otoro.colobus-ratio.ts.net";
              };
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
                User = "git";
              };

              "*" =
                lib.hm.dag.entryAfter
                  [
                    "aur.archlinux.org"
                    "bastion"
                    "github.com"
                    "homeassistant"
                    "otoro"
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
          ".ssh/config".force = true;
          ".ssh/id_rsa_yubikey.pub".source = ../../users/gabe/gpg.pub;
          ".ssh/id_ed25519.pub".source = ../../users/gabe/ssh.pub;
        };

        # materialize the config because openssh rejects nix store ownership in uid-isolated terminals
        home.activation.materializeSshConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          sshConfig="$HOME/.ssh/config"
          sshConfigSource="$(readlink -f "$sshConfig")"
          sshConfigTmp="$sshConfig.hm-tmp"

          run rm -f "$sshConfigTmp"
          run install -m 0400 "$sshConfigSource" "$sshConfigTmp"
          run mv -f "$sshConfigTmp" "$sshConfig"
        '';
      };
  };
}
