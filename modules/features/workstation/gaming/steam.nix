{
  den.aspects.steam = {
    nixos =
      {
        host,
        inputs',
        config,
        pkgs,
        lib,
        ...
      }:
      let
        primaryOutput = lib.findFirst (monitor: monitor.primary) null host.settings.monitors.monitors;
      in
      {
        programs.steam = {
          enable = true;

          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;

          gamescopeSession = {
            enable = true;
            args = [
              "--hdr-enabled"
              "--adaptive-sync"
            ]
            ++ lib.optionals (primaryOutput != null) [
              "--prefer-output"
              primaryOutput.name
            ];
          };
          protontricks.enable = true;

          extest.enable = true;

          extraPackages = with pkgs; [ mangohud ];
          extraCompatPackages = [
            inputs'.chaotic.packages.proton-cachyos
            inputs'.chaotic.packages.proton-ge-custom # instead of pkgs.proton-ge-bin
          ];
        };

        programs.gamescope = {
          enable = true;
          capSysNice = false; # doesn't work inside of steam
          package = inputs'.chaotic.packages.gamescope_git; # cachyos git build
        };

        # wires the cachyos git WSI builds in; the gamescope module's enableWsi would
        # otherwise add the nixpkgs gamescope-wsi pair, mismatching the git gamescope
        hardware.graphics = {
          extraPackages = [ inputs'.chaotic.packages.gamescope-wsi_git ];
          extraPackages32 = [ inputs'.chaotic.packages.gamescope-wsi32_git ];
        };

        programs.gamemode = {
          enable = true;

          settings = {
            general = {
              softrealtime = "on";
              inhibit_screensaver = 1;
            };
            gpu = {
              apply_gpu_optimisations = "accept-responsibility";
              gpu_device = 0;
              amd_performance_level = lib.mkIf host.settings.gpu.amd "high";
            };
          };
        };

        environment.systemPackages = with pkgs; [
          steamcmd
          steam-tui
        ];

        nixpkgs.config.packageOverrides = pkgs: {
          steam = pkgs.steam.override {
            extraEnv.DRI_PRIME = config.environment.sessionVariables.DRI_PRIME or null;

            extraPkgs =
              pkgs: with pkgs; [
                # extra xorg libs for gamescope
                # TODO: test if these are still needed
                libxcursor
                libxi
                libxinerama
                libxscrnsaver
                libpng
                libpulseaudio
                libvorbis
                stdenv.cc.cc.lib
                libkrb5
                keyutils

                # useful tools
                mangohud
                mesa-demos
              ];
          };
        };
      };
  };

  flake-file = {
    inputs.chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nixConfig = {
      extra-substituters = [
        "https://nyx-cache.chaotic.cx"
      ];
      extra-trusted-public-keys = [ "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=" ];
    };
  };
}
