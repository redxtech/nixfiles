{
  den.aspects.bluetooth = {
    nixos.hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    provides.for-workstation = {
      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        {
          services.blueman.enable = true;

          # TODO: maybe move to audio aspect?
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
            serviceConfig.ExecStart = lib.getExe' pkgs.bluez "mpris-proxy";
          };
        };

      homeManager =
        {
          osConfig,
          pkgs,
          lib,
          ...
        }:
        {
          home.packages = with pkgs; [
            bluetuith
          ];

          scripts.scripts = lib.mkIf osConfig.hardware.bluetooth.enable {
            fix-bluetooth = pkgs.writeShellApplication {
              name = "fix-bluetooth";
              runtimeInputs = [
                pkgs.bluez
                pkgs.coreutils
                pkgs.systemd
              ];
              text = builtins.readFile ./fix-bluetooth.sh;
            };
          };
        };
    };
  };
}
