{
  den.aspects.voyager-sleep = {
    nixos = {
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
        HibernateOnACPower = false;
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
            "--prefix PATH : ${
              lib.makeBinPath [
                pkgs.systemd
                pkgs.glib
                pkgs.libnotify
                inputs'.noctalia.packages.default
              ]
            }"
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

          # replace only voyager's shared idle action and preserve the lock/display timers
          idle.behavior.lock-and-suspend = lib.mkForce {
            action = "command";
            command = "${command} idle-threshold";
            enabled = true;
            resume_command = "${command} active";
            timeout = 1795.0;
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
