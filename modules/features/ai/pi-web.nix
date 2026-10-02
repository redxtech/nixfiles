{ self, lib, ... }:

{
  den.aspects.pi-web = {
    nixos =
      { config, ... }:
      {
        network.services.pi-web = 8504;
        networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
          8504
        ];
      };

    homeManager =
      { config, pkgs, ... }:
      let
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.pi-web;
        service = executable: description: {
          Unit.Description = description;
          Service = {
            ExecStart = "${package}/bin/${executable}";
            WorkingDirectory = "%h";
            Environment = [
              "PI_WEB_HOST=0.0.0.0"
              "PI_WEB_PORT=8504"
              "PATH=${
                lib.makeBinPath [
                  config.programs.pi-coding-agent.package
                  pkgs.nodejs_24
                  pkgs.git
                ]
              }:%h/.nix-profile/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin"
            ];
            UMask = "0077";
            Restart = "on-failure";
            RestartSec = 5;
          };
          Install.WantedBy = [ "default.target" ];
        };
      in
      {
        assertions = [
          {
            assertion = config.programs.pi-coding-agent.package.version == package.piVersion;
            message = "Pi Web's locked SDK must match the configured Pi Coding Agent version.";
          }
        ];

        home.packages = [ package ];

        systemd.user.services = {
          pi-web-sessiond = service "pi-web-sessiond" "Pi Web session daemon";
          pi-web = lib.recursiveUpdate (service "pi-web-server" "Pi Web interface") {
            Unit = {
              After = [ "pi-web-sessiond.service" ];
              Wants = [ "pi-web-sessiond.service" ];
            };
          };
        };
      };
  };
}
