{ config, pkgs, ... }:

{
  services = {
    calibre-server = {
      enable = true;

      user = config.nas.user;
      group = config.nas.group;
      port = config.nas.ports.calibre;

      libraries = [ "${config.nas.paths.media}/books" ];

      # auth.enable = true;
    };

    calibre-web = {
      enable = true;

      user = config.nas.user;
      group = config.nas.group;

      dataDir = "${config.nas.paths.data}/calibre-web";
      listen.port = config.nas.ports.calibre-web;
      openFirewall = true;

      options = {
        enableBookConversion = true;
        enableBookUploading = true;

        calibreLibrary = "${config.nas.paths.media}/books";
      };
    };
  };
}

