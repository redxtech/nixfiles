{ den, lib, ... }:

{
  den.aspects.server = {
    settings = {
      user = lib.mkOption {
        type = lib.types.str;
        default = "data";
        description = "User that owns shared server data.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "data";
        description = "Group that owns shared server data.";
      };

      uid = lib.mkOption {
        type = lib.types.int;
        default = 911;
        description = "UID of the shared server user.";
      };

      gid = lib.mkOption {
        type = lib.types.int;
        default = 911;
        description = "GID of the shared server group.";
      };

      configRoot = lib.mkOption {
        type = lib.types.str;
        default = "/config/pods";
        description = "Persistent service configuration root.";
      };

      dataRoot = lib.mkOption {
        type = lib.types.str;
        default = "/pool/data";
        description = "Persistent application data root.";
      };

      downloadsRoot = lib.mkOption {
        type = lib.types.str;
        default = "/pool/downloads";
        description = "Persistent downloads root.";
      };

      mediaRoot = lib.mkOption {
        type = lib.types.str;
        default = "/pool/media";
        description = "Persistent media root.";
      };

      legacySopsFile = lib.mkOption {
        type = lib.types.path;
        default = ../../../oldflake/hosts/quasar/secrets.yaml;
        description = "Legacy Quasar SOPS file used by services pending secret migration.";
      };
    };

    includes = [
      den.aspects.base
      den.aspects.adguard
      den.aspects.cockpit
      den.aspects.coredns
      den.aspects.ddclient
      den.aspects.flood
      den.aspects.github-runner
      den.aspects.grafana
      den.aspects.hercules-ci-agent
      den.aspects.homepage
      den.aspects.loki
      den.aspects.network
      den.aspects.network._.server
      den.aspects.pocket-id
      den.aspects.portainer
      den.aspects.prometheus
      den.aspects.startpage
      den.aspects.traefik._.server
      den.aspects.uptime-kuma
      den.aspects.virtualisation._.containers
    ];

    nixos =
      {
        config,
        host,
        pkgs,
        ...
      }:
      let
        cfg = host.settings.server;
        ifTheyExist = groups: builtins.filter (group: config.users.groups ? ${group}) groups;
        otherUsersWithUID = lib.filterAttrs (
          name: user: name != cfg.user && (user.uid or null) == cfg.uid
        ) config.users.users;
        otherGroupsWithGID = lib.filterAttrs (
          name: group: name != cfg.group && (group.gid or null) == cfg.gid
        ) config.users.groups;
        roots = [
          cfg.configRoot
          cfg.dataRoot
          cfg.downloadsRoot
          cfg.mediaRoot
        ];
        requiredMounts = [
          (builtins.dirOf cfg.configRoot)
          cfg.dataRoot
          cfg.downloadsRoot
          cfg.mediaRoot
        ];
      in
      {
        assertions = [
          {
            assertion = lib.all (path: path != "" && lib.hasPrefix "/" path) roots;
            message = "Server persistent roots must be non-empty absolute paths.";
          }
          {
            assertion = otherUsersWithUID == { };
            message = "Server UID ${toString cfg.uid} is already assigned to another user.";
          }
          {
            assertion = otherGroupsWithGID == { };
            message = "Server GID ${toString cfg.gid} is already assigned to another group.";
          }
          {
            assertion = lib.all (mount: config.fileSystems ? ${mount}) requiredMounts;
            message = "Server persistent roots must use the expected /config and /pool mounts.";
          }
        ];

        users.users.${cfg.user} = {
          description = "Data User";
          shell = pkgs.fish;
          isSystemUser = true;
          group = cfg.group;
          uid = cfg.uid;
          extraGroups = [
            cfg.group
          ]
          ++ ifTheyExist [
            "deluge"
            "docker"
            "input"
            "libvirtd"
            "network"
            "podman"
          ];
        };
        users.groups.${cfg.group}.gid = cfg.gid;

        security.sudo.wheelNeedsPassword = false;
      };
  };
}
