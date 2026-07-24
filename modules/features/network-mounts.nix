{
  den.aspects.network-mounts = {
    nixos =
      { host, config, ... }:
      {
        # use systemd-tmpfiles to create mount point
        systemd.tmpfiles.rules =
          let
            user = host.settings.base.primaryUser;
            group = config.users.groups.${user}.name;
          in
          [
            "D! /mnt/sshfs 0755 ${user} ${group} -"
          ];
      };

    homeManager.programs.sftpman = {
      enable = true;

      defaultSshKey = "~/.ssh/id_ed25519";

      mounts = {
        config = {
          user = "gabe";
          host = "quasar";
          mountPoint = "/config";
        };
        pool = {
          user = "gabe";
          host = "quasar";
          mountPoint = "/pool";
        };
        # lake = {
        #   user = "gabe";
        #   host = "quasar";
        #   mountPoint = "/lake";
        # };
        rsync = {
          user = "fm1620";
          host = "fm1620.rsync.net";
          mountPoint = "";
        };
      };
    };
  };
}
