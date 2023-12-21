{ config, pkgs, ... }:

{
  programs.zsh = { enable = true; };

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
}
