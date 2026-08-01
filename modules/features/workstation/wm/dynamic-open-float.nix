{
  den.aspects.niri-dynamic-open-float.homeManager = { pkgs, ... }: {
    systemd.user.services.niri-dynamic-open-float =
      let
        script = pkgs.writers.writePython3Bin "niri-dynamic-open-float" { doCheck = false; } (
          builtins.readFile ./dynamic-open-float.py
        );
      in
      {
        Unit = {
          Description = "Dynamically float matching niri windows";
          After = [ "niri.service" ];
          PartOf = [ "niri.service" ];
        };

        Service = {
          ExecStart = "${script}/bin/niri-dynamic-open-float";
          Restart = "on-failure";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
  };
}
