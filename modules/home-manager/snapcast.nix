{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf mkOption mkEnableOption;
  inherit (builtins) toString;
  cfg = config.services.snapcast;
in {
  options.services.snapcast = with lib.types; {
    enable = mkEnableOption "Enable Snapcast server";

    package = mkOption {
      type = package;
      default = pkgs.snapcast;
      description = "Snapcast package to use";
    };

    port = mkOption {
      type = port;
      default = 1704;
      description = "Port to listen on";
    };

    client = {
      enable = mkEnableOption "Enable Snapcast client";

      port = mkOption {
        type = port;
        default = 1704;
        description = "Port for the client to listen to";
      };

      host = mkOption {
        type = str;
        default = "localhost";
        description = "Host to listen to";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.snapserver = {
      Unit = {
        Description = "Snapcast audio player";
        Documentation = [ "https://github.com/badaix/snapcast" ];
        After = [ "network.target" "sound.target" ];
      };

      Service = {
        ExecStart = let
          configFile = pkgs.writeText "snapserver.conf" ''
            [http]
            doc_root = ${pkgs.snapcast}/share/snapserver/snapweb/

            [stream]
            source = pipe:///tmp/snapfifo?name=Mopidy&sampleformat=48000:16:2&control_url=http://bastion:6680/iris/
          '';
        in "${cfg.package}/bin/snapserver -c ${configFile}";
      };

      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services.snapclient = mkIf cfg.client.enable {
      Unit = {
        Description = "Snapcast client";
        Documentation = [ "https://github.com/badaix/snapcast" ];
        After = [ "snapserver.service" ];
      };

      Service = {
        ExecStart =
          "${cfg.package}/bin/snapclient -p ${toString cfg.client.port} -h ${
            toString cfg.client.host
          }";
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
