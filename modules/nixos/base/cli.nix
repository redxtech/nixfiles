{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf;
  cfg = config.base;
in {
  # options.base.cli = { };

  config = mkIf cfg.enable {
    # fish enables this, but it takes so long to build so i'm disabling it
    documentation.man.generateCaches = false;

    programs = {
      zsh = { enable = true; };

      fish = {
        enable = true;
        useBabelfish = true;
      };

      # nix helper tool (viperML/nh)
      nh = {
        enable = true;
        flake = "/home/${config.base.primaryUser}/Code/nixfiles";
        clean = {
          enable = true;
          extraArgs = "--keep-since 4d --keep 3";
        };
      };
    };

    environment = {
      shellAliases = let
        nr = "nh os";
        hm = "nh home";
      in rec {
        nrs = "${nr} switch";
        nru = "${nrs} --ask --update";
        snrs = "sudo nixos-rebuild --flake $FLAKE switch";

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
        rclone
        ripgrep
        tealdeer
        tmux
        yadm
        yt-dlp
        zoxide

        # nix helper, better nixos-rebuild
        nh
      ];

      pathsToLink = [ "/share/zsh" ];
    };
  };
}
