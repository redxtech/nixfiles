{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf;
  cfg = config.desktop;
  gaming = config.desktop.gaming;
in {
  options.desktop.gaming = let inherit (lib) mkOption mkEnableOption;
  in with lib.types; {
    enable = mkEnableOption "Enable gaming-related settings.";

    prime = {
      enable = mkOption {
        type = bool;
        default = cfg.isLaptop;
        defaultText = "config.desktop.isLaptop";
        description = "Enable NVIDIA PRIME support.";
      };

      internal = mkOption {
        type = nullOr str;
        default = null;
        description = "PCI ID of the internal GPU.";
      };

      dedicated = mkOption {
        type = nullOr str;
        default = null;
        description = "PCI ID of the dedicated GPU.";
      };
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

      enableMoonDeckBuddy = mkOption {
        type = bool;
        default = true;
        description = "Enable the moondeck buddy companion app.";
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

  config = mkIf (cfg.enable && gaming.enable) {
    assertions = [
      {
        assertion = gaming.prime.enable -> gaming.prime.internal != null;
        message = "prime.internal must be set if prime.enable is true";
      }
      {
        assertion = gaming.prime.enable -> gaming.prime.dedicated != null;
        message = "prime.dedicated must be set if prime.enable is true";
      }
    ];

    programs = {
      steam = {
        enable = true;

        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;

        protontricks.enable = true;

        gamescopeSession = {
          enable = true;
          env.DRI_PRIME = mkIf gaming.prime.enable gaming.prime.dedicated;
        };

        extraPackages = with pkgs; [ mangohud ];
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
      };

      gamescope = {
        enable = true;
        capSysNice = false; # doesn't work inside of steam

        # requires `hardware.nvidia.prime.offload.enable`.
        env = mkIf (gaming.nvidia && gaming.prime.enable) {
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
            amd_performance_level = mkIf gaming.amd "high";
          };
        };
      };
    };

    services.udev.packages = [ pkgs.game-devices-udev-rules ];

    services.sunshine = mkIf gaming.sunshine.enable {
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

        output_name = gaming.sunshine.monitorIndex;
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
          #       ${pkgs.bash}/bin/bash -c "${pkgs.xorg.xrandr}/bin/xrandr --output ${gaming.sunshine.monitor} --mode \"''${SUNSHINE_CLIENT_WIDTH}x''${SUNSHINE_CLIENT_HEIGHT}\" --rate ''${SUNSHINE_CLIENT_FPS}"
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
          {
            name = "MoonDeckStream";
            command = "${pkgs.moondeck-buddy}/bin/MoonDeckStream";
            image-path = "steam.png";
            auto-detach = "false";
            wait-all = "false";
          }
        ];
      };
    };

    # enable moondeck-buddy if selected
    systemd.user.services.moondeck-buddy =
      mkIf (gaming.sunshine.enable && gaming.sunshine.enableMoonDeckBuddy) {
        unitConfig = {
          Description = "MoonDeckBuddy";
          After = [ "graphical-session.target" ];
        };
        serviceConfig = {
          ExecStart = "${pkgs.moondeck-buddy}/bin/MoonDeckBuddy";
          Restart = "on-failure";
        };
        wantedBy = [ "graphical-session.target" ];
      };

    # hardware.bumblebee.enable = mkIf gaming.prime.enable true;
    hardware.nvidia.prime.offload.enable = mkIf gaming.prime.enable true;
    hardware.steam-hardware.enable = true;
    hardware.xpadneo.enable = true;
    hardware.xone.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    environment.sessionVariables = mkIf (gaming.amd && gaming.prime.enable) {
      DRI_PRIME = gaming.prime.internal;
      DRI_PRIME_INTERNAL = gaming.prime.internal;
      DRI_PRIME_DEDICATED = gaming.prime.dedicated;
    };

    environment.systemPackages = with pkgs;
      [
        # steam
        protonup-qt
        steamcmd
        steam-tui
        protontricks
        umu-launcher
        (lutris.override {
          extraPkgs = p: [ p.proton-ge-bin p.umu-launcher p.wine ];
        })
        game-devices-udev-rules

        # games
        heroic
        prismlauncher

        # tools
        mangohud

        # controller compad
        SDL2
      ] ++ (lib.optional gaming.sunshine.enable pkgs.moondeck-buddy);

    nixpkgs.config.nvidia.acceptLicense = true;

    nixpkgs.config.packageOverrides = pkgs: {
      steam = pkgs.steam.override {
        extraEnv.DRI_PRIME = mkIf gaming.prime.enable gaming.prime.dedicated;
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
            mesa-demos
          ];
      };
    };
  };
}
