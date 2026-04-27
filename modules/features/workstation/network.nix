{
  den.aspects.network = {
    nixos =
      { lib, ... }:
      {
        # disable networkmanager-wait-online
        systemd.services.NetworkManager-wait-online.enable = lib.mkDefault false;

        networking.networkmanager = {
          enable = lib.mkDefault true;
          wifi.backend = "iwd";
        };
      };
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          slurm-nm # network monitor
        ];
        services.network-manager-applet.enable = true;
      };
  };
}
