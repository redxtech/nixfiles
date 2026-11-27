{
  den.aspects.voyager-sleep = {
    nixos = { pkgs, ... }: {
      services.logind.settings.Login = {
        # the session observer routes managed events, with fail-closed native fallbacks
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
        HandleSuspendKey = "ignore";
        IdleAction = "ignore";
        SleepOperation = "suspend-then-hibernate";
      };

      systemd.sleep.settings.Sleep = {
        AllowHibernation = true;
        AllowSuspendThenHibernate = true;
        HibernateDelaySec = "30min";
        HibernateOnACPower = true;
      };

      # systemd has one hibernation delay, so select it when native sleep starts
      systemd.services.systemd-suspend-then-hibernate = {
        preStart = ''
          delay=30min
          if ${pkgs.systemd}/bin/systemd-ac-power; then
            delay=2h
          else
            status=$?
            if [ "$status" -ne 1 ]; then
              exit "$status"
            fi
          fi
          directory=/run/systemd/sleep.conf.d
          ${pkgs.coreutils}/bin/install -d -m 0755 "$directory"
          temporary=$(${pkgs.coreutils}/bin/mktemp "$directory/.voyager.XXXXXX")
          trap '${pkgs.coreutils}/bin/rm -f "$temporary"' EXIT
          printf '[Sleep]\nHibernateDelaySec=%s\n' "$delay" > "$temporary"
          ${pkgs.coreutils}/bin/chmod 0644 "$temporary"
          ${pkgs.coreutils}/bin/mv -f "$temporary" "$directory/90-voyager.conf"
        '';
        postStop = ''
          ${pkgs.coreutils}/bin/rm -f /run/systemd/sleep.conf.d/90-voyager.conf
        '';
      };
    };

    homeManager =
      {
        inputs',
        pkgs,
        lib,
        ...
      }:
      let
        coordinator = pkgs.python3Packages.buildPythonApplication {
          pname = "voyager-sleep";
          version = "0.1.0";
          pyproject = false;
          src = ./sleep.py;
          dontUnpack = true;
          dontBuild = true;

          installPhase = ''
            runHook preInstall
            install -Dm755 "$src" "$out/bin/voyager-sleep"
            runHook postInstall
          '';

          makeWrapperArgs = [
            "--prefix"
            "PATH"
            ":"
            (lib.makeBinPath [
              pkgs.systemd
              pkgs.glib
              pkgs.libnotify
              inputs'.noctalia.packages.default
            ])
          ];

          installCheckPhase = ''
            runHook preInstallCheck
            "$out/bin/voyager-sleep" --help >/dev/null
            runHook postInstallCheck
          '';

          meta.mainProgram = "voyager-sleep";
        };
        command = lib.getExe coordinator;
      in
      {
        home.packages = [ coordinator ];

        programs.noctalia.settings = {
          hooks.started = lib.mkAfter [ "systemctl --user restart voyager-sleep.service" ];

          # keep the battery threshold latched while AC waits for its longer timeout
          idle.behavior = {
            lock-and-suspend = lib.mkForce {
              action = "command";
              command = "${command} idle-threshold";
              enabled = true;
              resume_command = "${command} active";
              timeout = 1795.0;
            };
            ac-suspend = {
              action = "command";
              command = "${command} idle-threshold --ac";
              enabled = true;
              resume_command = "${command} active";
              timeout = 3595.0;
            };
          };

          shell.session.power.suspend = "${command} request manual";
        };

        programs.niri.settings.binds.XF86Sleep = {
          allow-when-locked = true;
          repeat = false;
          action.spawn = [
            command
            "request"
            "sleep-key"
          ];
        };

        systemd.user.services.voyager-sleep = {
          Unit = {
            Description = "Observe Voyager session power events and admit managed sleep requests";
            After = [ "noctalia.service" ];
            PartOf = [
              "noctalia.service"
              "graphical-session.target"
            ];
          };
          Service = {
            ExecStartPre = "${lib.getExe' pkgs.glib "gdbus"} wait --session org.kde.StatusNotifierWatcher";
            ExecStart = lib.escapeShellArgs [
              (lib.getExe' pkgs.systemd "systemd-inhibit")
              "--what=handle-lid-switch:handle-suspend-key"
              "--mode=block"
              "--who=Voyager sleep observer"
              "--why=Prepare Bitwarden before managed sleep"
              command
              "observer"
              # systemd expands this before systemd-inhibit clears the variable
              "--notify-socket"
              "\${NOTIFY_SOCKET}"
            ];
            Type = "notify";
            NotifyAccess = "all";
            Restart = "on-failure";
            RestartSec = 2;
            KillMode = "control-group";
            TimeoutStartSec = 30;
            TimeoutStopSec = 75;
            UMask = "0077";
          };
          Install.WantedBy = [ "noctalia.service" ];
        };
      };
  };
}
