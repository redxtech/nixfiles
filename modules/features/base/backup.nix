{ den, ... }:

{
  den.aspects.backup.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (builtins) listToAttrs map substring;
      inherit (lib)
        attrsToList
        mkEnableOption
        mkIf
        mkMerge
        mkOption
        types
        ;

      cfg = config.backup;
    in
    {
      options.backup = {
        btrfs = {
          enable = mkEnableOption "btrfs snapshot backups";

          subvolumes = mkOption {
            type = types.attrsOf types.path;
            default = { };
            description = "Name-path mappings to back up with btrfs without crossing subvolumes";
          };

          interval = mkOption {
            type = types.str;
            default = "daily";
            description = "Interval for btrfs snapshots via snapper";
          };
        };

        rsync = {
          enable = mkEnableOption "rsync backups";

          paths = mkOption {
            type = types.listOf types.path;
            default = [ ];
            description = "Paths to back up with rsync";
          };

          destination = mkOption {
            type = types.str;
            description = "Rsync destination for backups";
          };

          interval = mkOption {
            type = types.str;
            default = "daily";
            description = "Interval for rsync backups";
          };
        };

        restic = {
          enable = mkEnableOption "restic backups";
          backups = {
            config = {
              enable = mkEnableOption "configuration backups";

              repoFile = mkOption {
                type = types.path;
                description = "Path to the restic repository file";
              };

              passFile = mkOption {
                type = types.path;
                description = "Path to the restic repository password file";
              };

              extraPaths = mkOption {
                type = types.listOf types.path;
                default = [ ];
                description = "Extra paths to include in the configuration backup";
              };
            };

            home = {
              enable = mkEnableOption "home directory backups";

              repoFile = mkOption {
                type = types.path;
                description = "Path to the restic repository file";
              };

              passFile = mkOption {
                type = types.path;
                description = "Path to the restic repository password file";
              };

              extraPaths = mkOption {
                type = types.listOf types.path;
                default = [ ];
                description = "Extra paths to include in the home directory backup";
              };
            };
          };
        };

        # TODO: add zfs snapshots
      };

      config = mkMerge [
        (mkIf cfg.btrfs.enable {
          environment.systemPackages = [
            pkgs.snapper
            pkgs.snapper-gui
          ];

          services.snapper = {
            snapshotInterval = cfg.btrfs.interval;
            configs = listToAttrs (
              map ({ name, value }: {
                inherit name;
                value = {
                  SUBVOLUME = value;
                  TIMELINE_CREATE = true;
                  TIMELINE_CLEANUP = true;
                };
              }) (attrsToList cfg.btrfs.subvolumes)
            );
          };
        })

        (mkIf cfg.rsync.enable {
          environment.systemPackages = [ pkgs.rsync ];

          systemd =
            let
              dropFirst = string: substring 1 (lib.stringLength string - 1) string;
              slugPath = path: lib.replaceStrings [ "/" ] [ "-" ] (dropFirst path);

              mkTimer = path: {
                name = "backup-rsync-${slugPath path}";
                value = {
                  description = "Trigger rsync backup for ${slugPath path}";
                  timerConfig = {
                    Unit = "backup-rsync-${slugPath path}.service";
                    OnCalendar = cfg.rsync.interval;
                  };
                  wantedBy = [ "timers.target" ];
                };
              };

              mkService =
                path:
                let
                  pathSlug = slugPath path;
                  command = pkgs.writeShellApplication {
                    name = "backup-rsync-${pathSlug}";
                    runtimeInputs = [
                      pkgs.openssh
                      pkgs.rsync
                    ];
                    text = ''
                      rsync \
                        --archive \
                        --compress \
                        --delete \
                        --inplace \
                        --partial \
                        --progress \
                        --verbose \
                        ${path} ${cfg.rsync.destination}/${pathSlug}
                    '';
                  };
                in
                {
                  name = "backup-rsync-${pathSlug}";
                  value = {
                    description = "Back up ${pathSlug} to the rsync destination";
                    serviceConfig = {
                      Type = "oneshot";
                      ExecStart = lib.getExe command;
                    };
                  };
                };
            in
            {
              timers = listToAttrs (map mkTimer cfg.rsync.paths);
              services = listToAttrs (map mkService cfg.rsync.paths);
            };
        })

        (mkIf cfg.restic.enable {
          environment.systemPackages = [ pkgs.restic ];

          services.restic.backups =
            let
              inherit (cfg.restic) backups;
              timerConfig = {
                OnCalendar = "daily";
                Persistent = true;
              };
            in
            {
              config = mkIf backups.config.enable {
                inherit timerConfig;
                repositoryFile = backups.config.repoFile;
                passwordFile = backups.config.passFile;
                paths = [ "/var/lib" ] ++ backups.config.extraPaths;
                initialize = true;
              };

              home = mkIf backups.home.enable {
                inherit timerConfig;
                repositoryFile = backups.home.repoFile;
                passwordFile = backups.home.passFile;
                paths = [ "/home" ] ++ backups.home.extraPaths;
                exclude = [
                  "/home/*/.cache"
                  "/home/*/.local/share/Steam"
                  "/home/*/.steam"
                  "/home/**/node_modules"
                  "/home/**/.venv"
                ];
                initialize = true;
              };
            };

          users.users.restic = {
            isNormalUser = true;
            createHome = false;
          };

          security.wrappers.restic = {
            source = lib.getExe pkgs.restic;
            owner = "restic";
            group = "users";
            permissions = "u=rwx,g=,o=";
            capabilities = "cap_dac_read_search=+ep";
          };
        })
      ];
    };
}
