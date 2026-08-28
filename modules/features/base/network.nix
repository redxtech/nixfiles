{
  den.aspects.networking = {
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

        # duplicated by network-manager
        hardware.facter.detected.dhcp.enable = false;

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
