{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.nas;
  ifTheyExist = groups:
    builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  options.nas = {
    enable = mkEnableOption "NAS configuration";
    useNative = mkEnableOption "Use native services instead of containers";

    domain = mkOption {
      type = types.str;
      description = "Domain to use for NAS services";
      default = "nas.local";
    };

    user = mkOption {
      type = types.str;
      description = "User to run NAS services as";
      default = "data";
    };

    group = mkOption {
      type = types.str;
      description = "Group to run NAS services as";
      default = "data";
    };

    timezone = mkOption {
      type = types.str;
      description = "Timezone to use";
      default = "America/Vancouver";
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

      extraGroups = [ cfg.group ] ++ ifTheyExist [
        "deluge"
        "docker"
        "input"
        "libvirtd"
        "network"
        "podman"
      ];
    };
    users.groups.${cfg.group} = { };

    time.timeZone = cfg.timezone;

    # container config
    virtualisation = {
      docker = {
        enable = true;

        # TODO: re-enable

        # storageDriver = "zfs";
        # enableNvidia = true;
      };

      oci-containers = { backend = "docker"; };
    };
  };
}
