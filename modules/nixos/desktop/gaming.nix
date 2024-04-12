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

    sunshine = {
      enable = mkOption {
        type = bool;
        default = false;
        description = "Enable the sunshine host for moonlight streaming.";
      };

      monitor = mkOption {
        type = str;
        default = "DisplayPort-0";
        description = "The primary monitor to use for the sunshine host.";
      };

      monitorIndex = mkOption {
        type = int;
        default = 0;
        description =
          "The index of the primary monitor to use for the sunshine host.";
      };
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

    services.udev.packages = [ pkgs.game-devices-udev-rules ];

    services.sunshine = mkIf cfg.gaming.sunshine.enable {
      enable = true;
      openFirewall = true;
      capSysAdmin = true;

      settings = {
        sunshine_name = let
          capitalize = str:
            let
              charsRaw = lib.splitString "" str;
              chars = lib.tail charsRaw; # drop the empty string at the start
              firstChar = lib.toUpper (lib.head chars);
              restChars = lib.tail chars;
            in (firstChar + (lib.concatStrings restChars));
        in (capitalize config.networking.hostName);

        output_name = cfg.gaming.sunshine.monitorIndex;
      };

      applications = {
        env = { PATH = "$(PATH):$(HOME)/.local/bin"; };
        apps = [
          {
            name = "Desktop";
            image-path = "desktop.png";
          }
          # TODO: fix this
          # {
          #   name = "Desktop (Resized)";
          #   prep-cmd = [{
          #     do = ''
          #       ${pkgs.bash}/bin/bash -c "${pkgs.xorg.xrandr}/bin/xrandr --output ${cfg.gaming.sunshine.monitor} --mode \"''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}\" --rate ''${SUNSHINE_CLIENT_FPS}"
          #     '';
          #     undo = "${pkgs.autorandr}/bin/autorandr --change";
          #   }];
          #   # exclude-global-prep-cmd = "false";
          #   # auto-detach = "true";
          #   image-path = "desktop-alt.png";
          # }
          {
            name = "Steam Big Picture";
            output = "steam.txt";
            detached = [
              "${pkgs.util-linux}/bin/setsid ${pkgs.steam}/bin/steam steam://open/bigpicture"
            ];
            image-path = "steam.png";
          }
        ];
      };
    };

    # hardware.bumblebee.enable = mkIf cfg.gaming.prime true;
    hardware.nvidia.prime.offload.enable = mkIf cfg.gaming.prime true;
    hardware.steam-hardware.enable = true;
    hardware.xpadneo.enable = true;
    hardware.xone.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    environment.systemPackages = with pkgs;
      [
        # steam
        protonup-qt
        steamcmd
        steam-tui
        prismlauncher-qt5
        protontricks
        (lutris.override { extraPkgs = p: [ p.wine ]; })
        game-devices-udev-rules

        # games
        prismlauncher

        # tools
        mangohud
      ] ++ (lib.optional cfg.gaming.sunshine.enable pkgs.moondeck-buddy);

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
