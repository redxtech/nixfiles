{ config, pkgs, lib, ... }:

{
  services = {
    caffeine = { enable = false; };

    clipman = { enable = false; };
  };

  systemd.user.services = {
    gpaste = {
      Unit = {
        Description = "Start gpaste daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        Type = "dbus";
        BusName = "org.gnome.GPaste";
        ExecStart = "${pkgs.gnome.gpaste}/libexec/gpaste/gpaste-daemon";
      };
    };

    # TODO: sort out polkit

    # polkit-authentication-agent = {
    #   Unit = {
    #     Description = "Polkit authentication agent";
    #     Documentation = "https://gitlab.freedesktop.org/polkit/polkit/";
    #     After = [ "graphical-session-pre.target" ];
    #     PartOf = [ "graphical-session.target" ];
    #   };

    #   Service = {
    #     ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    #     Restart = "always";
    #     BusName = "org.freedesktop.PolicyKit1.Authority";
    #   };

    #   Install.WantedBy = [ "graphical-session.target" ];
    # };
  };
}

