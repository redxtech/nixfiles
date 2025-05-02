{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.nas;
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  options.nas = {
    enable = mkEnableOption "NAS configuration";

    domain = mkOption {
      type = types.str;
      description = "Domain to use for NAS services";
      default = "nas.local";
    };

    user = mkOption {
      type = types.str;
      description = "user to run nas services as";
      default = "data";
    };

    group = mkOption {
      type = types.str;
      description = "group to run nas services as";
      default = "data";
    };

    uid = mkOption {
      type = types.int;
      description = "user id to run nas services as";
      default = 911;
    };

    gid = mkOption {
      type = types.int;
      description = "group to run nas services as";
      default = 911;
    };

    timezone = mkOption {
      type = types.str;
      description = "Timezone to use";
      default = "America/Edmonton";
    };

    paths = {
      pool = mkOption {
        type = types.path;
        description = "Directory of the pool";
        default = "/pool";
      };

      config = mkOption {
        type = types.path;
        description = "Directory for the config mount points";
        default = "${cfg.paths.pool}/config";
        defaultText = "\${config.nas.paths.pool}/config";
      };

      data = mkOption {
        type = types.path;
        description = "Directory for the data mount points";
        default = "${cfg.paths.pool}/data";
        defaultText = "\${config.nas.paths.pool}/data";
      };

      downloads = mkOption {
        type = types.path;
        description = "Directory for the downloads mount points";
        default = "${cfg.paths.pool}/downloads";
        defaultText = "\${config.nas.paths.pool}/downloads";
      };

      media = mkOption {
        type = types.path;
        description = "Directory for the media mount points";
        default = "${cfg.paths.pool}/media";
        defaultText = "\${config.nas.paths.pool}/media";
      };
    };

    # allow specifying ports and services to use in config in the format of { service = port }
    ports = mkOption {
      type = types.attrsOf types.int;
      description = "Ports to use for services";
      default = { }; # TODO: add defaults
    };
  };

  config = mkIf cfg.enable {

    # user config
    users.users.${cfg.user} = {
      description = "Data User";
      shell = pkgs.fish;
      isSystemUser = true;
      group = cfg.group;
      uid = cfg.uid;

      extraGroups = [ cfg.group ] ++ ifTheyExist [
        "deluge"
        "docker"
        "input"
        "libvirtd"
        "network"
        "podman"
      ];
    };
    users.groups.${cfg.group}.gid = cfg.gid;

    # add netdata to group if enabled
    users.groups.netdata = lib.mkIf config.services.netdata.enable { };

    time.timeZone = cfg.timezone;

    # container config
    virtualisation = {
      docker = {
        enable = true;

        # TODO: re-enable
        # storageDriver = "zfs";
      };

      oci-containers = { backend = "docker"; };
    };
  };
}
