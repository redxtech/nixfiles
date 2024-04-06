{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf;
  cfg = config.desktop;
in {
  options.desktop.gaming = let inherit (lib) mkOption mkEnableOption;
  in with lib.types; {
    enable = mkEnableOption "Enable gaming-related settings.";

    prime = mkOption {
      type = bool;
      default = cfg.isLaptop;
      defaultText = "config.desktop.isLaptop";
      description = "Enable NVIDIA PRIME support.";
    };

    amd = mkOption {
      type = bool;
      default = false;
      description = "Enable AMD driver support.";
    };

    nvidia = mkOption {
      type = bool;
      default = false;
      description = "Enable NVIDIA driver support.";
    };

    sunlight = mkOption {
      type = bool;
      default = false;
      description = "Enable the sunlight host for moonlight streaming.";
    };
  };

  config = mkIf (cfg.enable && cfg.gaming.enable) {
    programs = {
      steam = {
        enable = true;

        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = true;
      };

      gamescope = {
        enable = true;
        capSysNice = true;

        # requires `hardware.nvidia.prime.offload.enable`.
        env = mkIf cfg.gaming.prime {
          __NV_PRIME_RENDER_OFFLOAD = "1";
          __VK_LAYER_NV_optimus = "NVIDIA_only";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        };
      };

      gamemode = {
        enable = true;
        settings = {
          general = {
            softrealtime = "on";
            inhibit_screensaver = 1;
          };
          gpu = {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
            amd_performance_level = mkIf cfg.gaming.amd "high";
          };
        };
      };
    };

    services.sunshine = mkIf cfg.gaming.sunlight {
      enable = true;
      openFirewall = true;
      capSysAdmin = true;
    };

    # hardware.bumblebee.enable = mkIf cfg.gaming.prime true;
    hardware.nvidia.prime.offload.enable = mkIf cfg.gaming.prime true;
    hardware.steam-hardware.enable = true;
    hardware.xpadneo.enable = true;
    hardware.xone.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    environment.systemPackages = with pkgs; [
      # steam
      protonup-qt
      steamcmd
      steam-tui
      prismlauncher-qt5
      protontricks
      (lutris.override { extraPkgs = p: [ p.wine ]; })

      # games
      prismlauncher

      # tools
      mangohud
    ];

    nixpkgs.config.nvidia.acceptLicense = true;

    nixpkgs.config.packageOverrides = pkgs: {
      steam = pkgs.steam.override {
        extraPkgs = pkgs:
          with pkgs; [
            xorg.libXcursor
            xorg.libXi
            xorg.libXinerama
            xorg.libXScrnSaver
            libpng
            libpulseaudio
            libvorbis
            stdenv.cc.cc.lib
            libkrb5
            keyutils
            mangohud
            glxinfo
          ];
      };
    };
  };
}
