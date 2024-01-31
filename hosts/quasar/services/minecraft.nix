{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.nas;
  mkPorts = port: "${toString port}:${toString port}";
in {
  virtualisation.oci-containers = {
    containers = {
      minecraft = {
        image = "itzg/minecraft-server";
        ports = [ (mkPorts cfg.ports.minecraft) ];
        environment = {
          EULA = "TRUE";
          TYPE = "AUTO_CURSEFORGE";
          MEMORY = "4G";
          CF_SLUG = "monkys-mods-for-the-boys";
        };
        environmentFiles = [ config.sops.secrets."minecraft_cf.env".path ];
        volumes = [ (cfg.paths.config + "/minecraft:/data") ];
        # dependsOn = [ "minecraft-backup-restore" ];
        # extraOptions = [ "--tty" "--interactive" ];
      };
      minecraft-rcon-web = {
        image = "itzg/rcon";
        ports = [ (mkPorts 4326) (mkPorts 4327) ];
        environment = {
          RWA_USERNAME = "admin";
          RWA_PASSWORD = "admin";
          RWA_ADMIN = "TRUE";
          # is referring to the hostname of 'mc' compose service below
          RWA_RCON_HOST = "quasar";
          # needs to match the RCON_PASSWORD configured for the container
          RWA_RCON_PASSWORD = "demo";
        };
        volumes =
          [ (cfg.paths.config + "/minecraft/rcon:/opt/rcon-web-admin/db") ];
      };
      minecraft-backup = {
        image = "itzg/mc-backup";
        environment = {
          RCON_HOST = "quasar";
          BACKUP_INTERVAL = "2h";
          INITIAL_DELAY = "0";
        };
        dependsOn = [ "minecraft" ];
        volumes = [
          (cfg.paths.config + "/minecraft:/data")
          (cfg.paths.data + "/minecraft-backups:/backups:ro")
        ];
        extraOptions = [ "--restart" "no" ];
      };
      minecraft-backup-restore = {
        image = "itzg/mc-backup";
        entrypoint = "restore-tar-backup";
        volumes = [
          (cfg.paths.config + "/minecraft:/data:ro")
          (cfg.paths.data + "/minecraft-backups:/backups")
        ];
        extraOptions = [ "--restart" "no" ];
      };
    };
  };

  sops.secrets."minecraft_cf.env".sopsFile = ../secrets.yaml;
}
