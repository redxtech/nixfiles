{
  den.aspects.network = {
    nixos =
      { lib, ... }:
      {
        # disable networkmanager-wait-online
        systemd.services.NetworkManager-wait-online.enable = false;

        networking.networkmanager = {
          enable = lib.mkDefault true;
          wifi.backend = "iwd";
        };

        # networking.nftables.enable = mkDefault true; # TODO: enable when fixed in docker

        # needed for iwd
        services.gnome.gnome-keyring.enable = true;

        # TODO: look into networking.search
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          slurm-nm # network monitor
        ];
      };

    provides.for-workstation.homeManager.services.network-manager-applet.enable = true;
  };
}
