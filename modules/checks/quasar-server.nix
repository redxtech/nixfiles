{ inputs, ... }:

{
  perSystem =
    { pkgs, system, ... }:
    let
      inherit (inputs.nixpkgs) lib;
      serverAspect =
        (import ../features/server/server.nix {
          den = null;
          inherit lib;
        }).den.aspects.server;
      serverModule = serverAspect.nixos;
      serverSettings = lib.mapAttrs (_: option: option.default) serverAspect.settings;
      containerModule =
        (import ../features/base/virtualisation.nix).den.aspects.virtualisation.provides.containers.nixos;
      serverLib = import ../../lib/server { };

      testConfig =
        (lib.nixosSystem {
          inherit system;
          modules = [
            serverModule
            containerModule
            {
              _module.args.host.settings = {
                server = serverSettings;
                gpu.nvidia.enable = false;
              };

              fileSystems = {
                "/" = {
                  device = "none";
                  fsType = "tmpfs";
                };
                "/config" = {
                  device = "none";
                  fsType = "tmpfs";
                };
                "/pool/data" = {
                  device = "none";
                  fsType = "tmpfs";
                };
                "/pool/downloads" = {
                  device = "none";
                  fsType = "tmpfs";
                };
                "/pool/media" = {
                  device = "none";
                  fsType = "tmpfs";
                };
              };

              boot.loader.grub.devices = [ "nodev" ];
              programs.fish.enable = true;
              users.groups.libvirtd = { };

              virtualisation.oci-containers = {
                containers = {
                  app.image = "example/app:latest";
                  database.image = "example/database:latest";
                };
                networks.stack = [
                  "app"
                  "database"
                ];
              };

              system.stateVersion = "25.11";
            }
          ];
        }).config;

      networkUnit = testConfig.systemd.services.docker-network-stack;
      appUnit = testConfig.systemd.services.docker-app;
      networkDependency = "docker-network-stack.service";
      volumes = serverLib.volumes serverSettings;
    in
    lib.optionalAttrs (system == "x86_64-linux") {
      checks.quasar-server-substrate =
        assert builtins.seq testConfig.system.build.toplevel.drvPath true;
        assert testConfig.users.users.data.uid == 911;
        assert testConfig.users.groups.data.gid == 911;
        assert testConfig.users.users.data.group == "data";
        assert serverSettings.configRoot == "/config/pods";
        assert serverSettings.dataRoot == "/pool/data";
        assert serverSettings.downloadsRoot == "/pool/downloads";
        assert serverSettings.mediaRoot == "/pool/media";
        assert
          testConfig.users.users.data.extraGroups == [
            "data"
            "docker"
            "input"
            "libvirtd"
          ];
        assert testConfig.virtualisation.docker.enable;
        assert testConfig.virtualisation.oci-containers.backend == "docker";
        assert
          testConfig.virtualisation.oci-containers.containers.app.extraOptions == [ "--network=stack" ];
        assert !testConfig.security.sudo.wheelNeedsPassword;
        assert volumes.config "example" == "/config/pods/example:/config";
        assert volumes.data "example" == "/pool/data/example:/data";
        assert volumes.downloads "example" == "/pool/downloads/example:/downloads";
        assert volumes.allDownloads == "/pool/downloads:/downloads";
        assert volumes.media == "/pool/media:/media";
        assert
          serverLib.defaultEnvironment {
            uid = 911;
            gid = 911;
            timeZone = "America/Edmonton";
          } == {
            PUID = "911";
            PGID = "911";
            TZ = "America/Edmonton";
          };
        assert networkUnit.after == [ "docker.service" ];
        assert networkUnit.requires == [ "docker.service" ];
        assert networkUnit.serviceConfig.Type == "oneshot";
        assert networkUnit.serviceConfig.RemainAfterExit;
        assert lib.elem networkDependency appUnit.after;
        assert lib.elem networkDependency appUnit.requires;
        pkgs.runCommand "quasar-server-substrate-check" { } ''
          touch "$out"
        '';
    };
}
