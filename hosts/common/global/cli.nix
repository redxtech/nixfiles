{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    shellAliases = rec {
      nr = "nixos-rebuild --flake .";
      nrs = "${nr} switch";
      snr = "sudo ${nr}";
      snrs = "sudo ${nrs}";

      hm = "home-manager --flake .";
      hms = "${hm} switch";
      hmsb = "${hms} -b backup";
    };
  };

  environment.systemPackages = with pkgs; [
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

  environment.pathsToLink = [ "/share/zsh" ];
}
