{ pkgs, ... }:

{
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
          amd_performance_level = "high";
        };
      };
    };
  };

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
}
