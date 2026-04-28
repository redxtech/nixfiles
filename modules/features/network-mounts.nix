{
  den.aspects.network-mounts = {
    homeManager = {
      programs.sftpman = {
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
  };
}
