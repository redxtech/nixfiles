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
      paths = mkOption {
        type = listOf path;
        default = [ ];
        description = "Paths to backup with restic";
      };
    };

    # TODO: add zfs snapshots
  };

  config = let backupsEnabled = cfg.rsync.enable || cfg.btrfs.enable;
  in mkIf backupsEnabled {
    # include cli tools for enabled backup methods
    environment.systemPackages = with pkgs;
    # include rsync if enabled
      (optional cfg.rsync.enable rsync)
      # include snapper if btrfs backups enabled
      ++ (optionals cfg.btrfs.enable [ snapper snapper-gui ])
      # include restic if enabled
      ++ (optionals cfg.restic.enable [ restic ]);

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

    # enable restic backup
    users.users.restic = mkIf cfg.restic.enable { isNormalUser = true; };

    security.wrappers.restic = mkIf cfg.restic.enable {
      source = "${pkgs.restic.out}/bin/restic";
      owner = "restic";
      group = "users";
      permissions = "u=rwx,g=,o=";
      capabilities = "cap_dac_read_search=+ep";
    };
  };
}
