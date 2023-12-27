{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    shellAliases = {
      n = "nix";
      np = "nix-shell -p";
      nd = "nix develop -c $SHELL";
      ns = "nix shell";
      nsn = "nix shell nixpkgs#";
      nb = "nix build";
      nbn = "nix build nixpkgs#";
      nf = "nix flake";

      nr = "nixos-rebuild --flake .";
      nrs = "nixos-rebuild --flake . switch";
      snr = "sudo nixos-rebuild --flake .";
      snrs = "sudo nixos-rebuild --flake . switch";
      hm = "home-manager --flake .";
      hms = "home-manager --flake . switch";
      hmsb = "home-manager --flake . switch -b backup";
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
}
