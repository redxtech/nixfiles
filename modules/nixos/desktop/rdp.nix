{ pkgs, config, ... }:

let
  inherit mkIf;
  cfg = config.desktop;
in {
  options.desktop = let inherit (lib) mkOption;
  in with lib.types; {
    rdp.enable = mkOption {
      type = bool;
      default = false;
      description = "Enable RDP server";
    };
  };

  config = mkIf (cfg.enable && cfg.rdp.enable) {
    services.xrdp = {
      enable = true;
      openFirewall = true;
      defaultWindowManager = "${pkgs.gnome.gnome-session}/bin/gnome-session";
    };

    services.guacamole-server = {
      enable = true;
      # host = "0.0.0.0";

      extraEnvironment = { GUACAMOLE_HOME = "/etc/guacamole"; };

      # TODO: fix this to use a proper password w/ hash. also make it work lol
      userMappingXml = pkgs.writeText "user-mapping.xml" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <user-mapping>
        <authorize username="gabe" password="pw" encoding="plain">
        <protocol>rdp</protocol>
        <param name="hostname">localhost</param>
        <param name="port">3389</param>
        </authorize>
        </user-mapping>
      '';
    };

    services.guacamole-client = {
      enable = true;
      enableWebserver = true;
    };
  };
}
