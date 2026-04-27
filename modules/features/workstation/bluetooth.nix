{
  den.aspects.bluetooth = {
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        hardware.bluetooth.enable = true;
        hardware.bluetooth.powerOnBoot = true;

        services.blueman.enable = true;

        # add support for bluetooth headsets
        services.pipewire.wireplumber.extraConfig."10-bluez" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.headset-roles" = [
              "hsp_hs"
              "hsp_ag"
              "hfp_hf"
              "hfp_ag"
            ];
          };
        };

        systemd.user.services.mpris-proxy = lib.mkIf config.hardware.bluetooth.enable {
          description = "MPRIS proxy";
          after = [
            "network.target"
            "sound.target"
          ];
          wantedBy = [ "default.target" ];
          serviceConfig.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          bluetuith # tui bluetooth manager
        ];

        services.blueman-applet.enable = true;
      };
  };
}
