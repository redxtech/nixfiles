{ config, pkgs, ... }:

{
  programs = {
    zsh = { enable = true; };

    fish = {
      enable = true;
      useBabelfish = true;
    };
  };

  environment = {
    shellAliases = rec {
      nr = "nixos-rebuild --flake $FLAKE";
      nrs = "${nr} switch";
      nrb = "${nr} build";
      snr = "sudo ${nr}";
      snrs = "sudo ${nrs}";

      hm = "home-manager --flake .";
      hms = "${hm} switch";
      hmsb = "${hms} -b backup";
    };

    systemPackages = with pkgs; [
      atool
      bat
      btop
      cpustat
      dex
      eza
      fd
      ffmpeg
      fzf
      gh
      git
      jq
      lazygit
      mcfly
      mediainfo
      micro
      neofetch
      playerctl
      ranger
      rclone
      ripgrep
      tealdeer
      tmux
      yadm
      yt-dlp
      zoxide
    ];

    pathsToLink = [ "/share/zsh" ];
  };
}
