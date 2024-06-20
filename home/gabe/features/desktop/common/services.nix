{ config, pkgs, lib, ... }:

{
  services = {
    blueman-applet = { enable = false; };

    flameshot = { enable = false; };

    keybase = { enable = false; };
    megasync = { enable = false; };
    network-manager-applet = { enable = false; };
    plex-mpv-shim = { enable = false; };

    playerctld = { enable = true; };
    redshift = { enable = false; };

    signaturepdf = {
      enable = true;
      port = 9008;
    };

    spotifyd = {
      enable = false;

      settings = {
        global = {
          username = "redxtech";
          password_cmd =
            "${pkgs.coreutils}/bin/cat ${config.xdg.configHome}/spotify-tui/spotify.txt";

          use_mpris = true;
          backend = "pulseaudio";

          device_type = "computer";
          device_name = "desktop-spotifyd";

          bitrate = 320;
        };
      };
    };
  };
}
