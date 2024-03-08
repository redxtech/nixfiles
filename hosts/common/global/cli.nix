{ inputs, config, pkgs, ... }:

{
  programs = {
    zsh = { enable = true; };

    fish = {
      enable = true;
      useBabelfish = true;
    };
  };

  environment = {
    shellAliases = let
      nr = "nh os";
      hm = "nh home";
    in rec {
      nrs = "${nr} switch";
      nru = "${nrs} --ask --update";
      snrs = "sudo nixos-rebuild --flake $FLAKE --switch";

      hms = "${hm} switch";
      hmsu = "${hms} --ask --update";
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
      openssl
      playerctl
      ranger
      rclone
      ripgrep
      tealdeer
      tmux
      yadm
      yt-dlp
      zoxide

      # nix helper, better nixos-rebuild
      inputs.nh.packages.${pkgs.system}.default
    ];

    pathsToLink = [ "/share/zsh" ];
  };
}
