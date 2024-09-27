{ pkgs, lib, config, ... }:

let
  inherit (lib)
    attrsToList optional optionals mkIf mkOption mkEnableOption types;
  inherit (builtins) listToAttrs map substring;

  cfg = config.backup;
in {
  options.backup = with types; {
    btrfs = {
      enable = mkEnableOption "Enable btrfs backup (snapshots)";

      subvolumes = mkOption {
        type = attrsOf path;
        default = { };
        description =
          "Name-Path mappings to backup with btrfs (doesn't cross subvolumes)";
      };

      interval = mkOption {
        type = str;
        default = "daily";
        description = "Interval for btrfs snapshots via snapper";
      };
    };

    rsync = {
      enable = mkEnableOption "Enable rsync backup";

      paths = mkOption {
        type = listOf path;
        default = [ ];
        description = "Paths to backup with rsync";
      };

      destination = mkOption {
        type = str;
        default = null;
        description = "Rsync destination for backups";
      };

      interval = mkOption {
        type = str;
        default = "daily";
        description = "Interval for rsync backups";
      };
    };

    restic = {
      enable = mkEnableOption "Enable restic backup";
      backups = {
        config = {
          enable = mkEnableOption "Enable configuration backup";

          repoFile = mkOption {
            type = path;
            description = "Path to restic repository file";
          };

          passFile = mkOption {
            type = path;
            description = "Path to restic repository password file";
          };

          extraPaths = mkOption {
            type = listOf path;
            default = [ ];
            description = "Extra paths to include in config backup";
          };
        };
        home = {
          enable = mkEnableOption "Enable home folder backup";

          repoFile = mkOption {
            type = path;
            description = "Path to restic repository file";
          };

          passFile = mkOption {
            type = path;
            description = "Path to restic repository password file";
          };

          extraPaths = mkOption {
            type = listOf path;
            default = [ ];
            description = "Extra paths to include in home folder backup";
          };
        };
      };
    };

    # TODO: add zfs snapshots
  };

  config = lib.mkMerge [
    (mkIf cfg.btrfs.enable {
      environment.systemPackages = with pkgs; [ snapper snapper-gui ];

      # enable snapper for btrfs snapshot backups
      services.snapper = let
        mkSnapperConfig = { name, value }: {
          inherit name;
          value = {
            SUBVOLUME = value;
            TIMELINE_CREATE = true;
            TIMELINE_CLEANUP = true;
          };
        };
      in mkIf cfg.btrfs.enable {
        snapshotInterval = cfg.btrfs.interval;

        configs =
          listToAttrs (map mkSnapperConfig (attrsToList cfg.btrfs.subvolumes));
      };
    })

    (mkIf cfg.rsync.enable {
      environment.systemPackages = with pkgs; [ rsync ];

      # enable rsync backup
      systemd = let
        dropFirst = str: substring 1 (lib.stringLength str - 1) str;
        slugPath = path: lib.replaceStrings [ "/" ] [ "-" ] (dropFirst path);

        mkTimer = { description, service, schedule }: {
          inherit description;
          timerConfig = {
            Unit = service;
            OnCalendar = schedule;
          };
          wantedBy = [ "timers.target" ];
        };
        mkTimers = paths:
          listToAttrs (map (path:
            let spath = slugPath path;
            in {
              name = "backup-rsync-${spath}";
              value = mkTimer {
                description = "Trigger backup with rsync for ${spath}";
                service = "backup-rsync-${spath}.service";
                schedule = cfg.rsync.interval;
              };
            }) paths);

        mkService = { description, cmd }: {
          inherit description;
          serviceConfig = {
            Type = "oneshot";
            ExecStart = cmd;
          };
        };
        mkServices = paths:
          listToAttrs (map (path:
            let spath = slugPath path;
            in {
              name = "backup-rsync-${spath}";
              value = mkService {
                description = "Backup ${spath} to rsync destination";
                cmd = let
                  command = pkgs.writeShellApplication {
                    name = "backup-rsync-${spath}";
                    runtimeInputs = with pkgs; [ openssh rsync ];
                    text = ''
                      rsync \
                      --archive \
                      --compress \
                      --delete \
                      --inplace \
                      --partial \
                      --progress \
                      --verbose \
                      ${path} ${cfg.rsync.destination}/${spath}
                    '';
                  };
                in "${command}/bin/backup-rsync-${spath}";
              };
            }) paths);
      in mkIf cfg.rsync.enable {
        timers = mkTimers cfg.rsync.paths;
        services = mkServices cfg.rsync.paths;
      };
    })

    (mkIf cfg.restic.enable {
      environment.systemPackages = with pkgs; [ restic ];

      # enable restic backup
      services.restic.backups = let
        inherit (cfg.restic) backups;
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      in {
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
        source = "${pkgs.restic.out}/bin/restic";
        owner = "restic";
        group = "users";
        permissions = "u=rwx,g=,o=";
        capabilities = "cap_dac_read_search=+ep";
      };
    })
  ];
}
