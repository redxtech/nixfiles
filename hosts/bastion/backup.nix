{ pkgs, ... }:

{
  # Enable cron service
  services.cron = let
    backup-rsync = pkgs.writeShellApplication {
      name = "backup-rsync";
      runtimeInputs = with pkgs; [ rsync ];
      text = ''
        host="$(hostname)"
      '';
    };
  in {
    enable = true;
    systemCronJobs = [ "*/5 * * * *      root    date >> /tmp/cron.log" ];
  };
}
