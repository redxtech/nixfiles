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
    };

    includes = [
      den.aspects.base
      den.aspects.adguard
      den.aspects.apprise
      den.aspects.bento
      den.aspects.bazarr
      den.aspects.beszel
      den.aspects.booklore
      den.aspects.calibre
      den.aspects.calibre-web
      den.aspects.cockpit
      den.aspects.coredns
      den.aspects.ddclient
      den.aspects.docktail
      den.aspects.esphome
      den.aspects.flaresolverr
      den.aspects.flood
      den.aspects.github-runner
      den.aspects.grafana
      den.aspects.hercules-ci-agent
      den.aspects.home-assistant
      den.aspects.homepage
      den.aspects.influxdb
      den.aspects.jackett
      den.aspects.jdownloader
      den.aspects.jellyfin
      den.aspects.jellyfin-vue
      den.aspects.jellyseerr
      den.aspects.kiwix
      den.aspects.koinsight
      den.aspects.ladder
      den.aspects.lidarr
      den.aspects.loki
      den.aspects.mosquitto
      den.aspects.music-assistant
      den.aspects.navidrome
      den.aspects.network
      den.aspects.network._.server
      den.aspects.node-red
      den.aspects.pocket-id
      den.aspects.paperless
      den.aspects.papra
      den.aspects.plex
      den.aspects.portainer
      den.aspects.prometheus
      den.aspects.prowlarr
      den.aspects.qbittorrent
      den.aspects.qdirstat
      den.aspects.qui
      den.aspects.radarr
      den.aspects.scrutiny
      den.aspects.signaturepdf
      den.aspects.sonarr
      den.aspects.startpage
      den.aspects.stirling-pdf
      den.aspects.syncthing
      den.aspects.tautulli
      den.aspects.tailscale._.server
      den.aspects.traefik._.server
      den.aspects.tubearchivist
      # disable until back to beach house
      # den.aspects.unpoller
      den.aspects.uptime-kuma
      den.aspects.virtualisation._.containers
      den.aspects.watchtower
      den.aspects.yt
      # disable until back to beach house
      # den.aspects.zigbee2mqtt
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
