{ lib, ... }:

{
  den.aspects.av.nixos =
    {
      host,
      config,
      pkgs,
      ...
    }:
    let
      primaryHome = config.users.users.${host.settings.base.primaryUser}.home;
      scanProfiles = {
        ingress = {
          description = "ClamAV ingress virus scanner";
          scanDirectories = [
            "${primaryHome}/Downloads"
            "${primaryHome}/Desktop"
            "/tmp"
            "/var/tmp"
          ];
          requiredDirectories = [
            primaryHome
            "/tmp"
            "/var/tmp"
          ];
          # run weekly on laptops instead of daily; the deep scan owns Sunday on desktops
          interval =
            if host.settings.workstation.isLaptop then "Mon, *-*-* 04:00:00" else "Mon..Sat *-*-* 04:00:00";
          conditionACPower = true;
          persistent = false;
        };

        deep = rec {
          description = "ClamAV deep virus scanner";
          scanDirectories = [
            "/home"
            "/var/lib"
            "/etc"
          ];
          requiredDirectories = scanDirectories;
          interval = "Sun *-*-* 04:00:00";
          conditionACPower = true;
          persistent = true;
        };
      };
      mkClamdscan =
        name:
        { scanDirectories, requiredDirectories, ... }:
        pkgs.writeShellScript name ''
          for path in ${lib.escapeShellArgs requiredDirectories}; do
            if [[ ! -d "$path" ]]; then
              echo "required scan directory does not exist: $path" >&2
              exit 2
            fi
          done

          scan_paths=()
          for path in ${lib.escapeShellArgs scanDirectories}; do
            if [[ -d "$path" ]]; then
              scan_paths+=("$path")
            fi
          done

          if (( ''${#scan_paths[@]} == 0 )); then
            echo "no scan directories exist" >&2
            exit 2
          fi

          exec ${lib.getExe' config.services.clamav.package "clamdscan"} \
            --wait \
            --ping=60:1 \
            --multiscan \
            --fdpass \
            --infected \
            --allmatch \
            "''${scan_paths[@]}"
        '';
      mkScanService =
        name: profile:
        lib.nameValuePair "clamdscan-${name}" {
          inherit (profile) description;
          requires = [ "clamav-daemon.service" ];
          after = [
            "clamav-daemon.service"
            "clamav-freshclam.service"
          ];
          wants = [ "clamav-freshclam.service" ];
          unitConfig = lib.optionalAttrs profile.conditionACPower { ConditionACPower = true; };
          serviceConfig = {
            Type = "oneshot";
            ExecStart = mkClamdscan "clamdscan-${name}" profile;
            SuccessExitStatus = [ 1 ];
            Slice = "system-clamav.slice";
          };
        };
      mkScanTimer =
        name: profile:
        lib.nameValuePair "clamdscan-${name}" {
          description = "Timer for ${profile.description}";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = profile.interval;
            Persistent = profile.persistent;
            Unit = "clamdscan-${name}.service";
          };
        };
    in
    {
      services.clamav = {
        daemon.enable = true;
        daemon.settings.ExcludePath = [
          "^/dev"
          "^/proc"
          "^/sys"
          "^/run"
          "^/var/lib/clamav(/|$)"
          "^/nix/store(/|$)"
          "^/pool/media(/|$)"
          "^/home/[^/]+/[.]cache(/|$)"
          "^/home/[^/]+/[.]npm(/|$)"
          "^/home/[^/]+/[.]local/share/Steam/steamapps(/|$)"
          "^/home/[^/]+/[.]local/share/PrismLauncher/instances(/|$)"
          "^/home/[^/]+/[.]local/share/flatpak/repo(/|$)"
          "^/home/[^/]+/[.]local/share/pnpm/store(/|$)"
          "^/home/[^/]+/(.*/)?[.]git/objects(/|$)"
          "^/home/[^/]+/(.*/)?[.]yarn/cache(/|$)"
          "^/home/[^/]+/(.*/)?node_modules(/|$)"
          "^/home/[^/]+/[.]vscode/extensions(/|$)"
          "^/home/[^/]+/[.]config/[^/]+/(.*/)?(Cache|Code Cache|GPUCache)(/|$)"
          "^/home/[^/]+/[.]var/app/[^/]+/(.*/)?(cache|Cache|Code Cache|GPUCache)(/|$)"
          "^/home/[^/]+/(Code|Work|Software)/(.*/)?([.]direnv|[.]venv|build|dist|target)(/|$)"
        ];

        updater.enable = config.services.clamav.daemon.enable;
        fangfrisch.enable = config.services.clamav.daemon.enable;
      };

      systemd = {
        services = (lib.mapAttrs' mkScanService scanProfiles) // {
          clamav-daemon = {
            wantedBy = lib.mkForce [ ];
            unitConfig.StopWhenUnneeded = true;
            serviceConfig.RuntimeDirectoryPreserve = true;
          };
        };
        timers = lib.mapAttrs' mkScanTimer scanProfiles;
      };

      # install gui app if a desktop
      environment.systemPackages = lib.optional host.settings.base.hasDisplay pkgs.clamtk;
    };
}
