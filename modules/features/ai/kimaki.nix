{
  den.aspects.kimaki.nixos =
    {
      self',
      inputs',
      host,
      lib,
      ...
    }:
    {
      users.users.${host.settings.base.primaryUser}.linger = true;

      environment.systemPackages = [ self'.packages.kimaki ];

      systemd.user.services.kimaki = {
        description = "Kimaki Discord agent orchestrator";
        wantedBy = [ "default.target" ];
        path = [ inputs'.llm-agents.packages.opencode ];

        unitConfig = {
          ConditionUser = host.settings.base.primaryUser;
          ConditionPathExists = "%h/.kimaki/discord-sessions.db";
        };

        serviceConfig = {
          ExecStart = "${lib.getExe self'.packages.kimaki} --no-auto-upgrade";
          Restart = "on-failure";
          RestartSec = "10s";
          WorkingDirectory = "%h";
        };
      };
    };
}
