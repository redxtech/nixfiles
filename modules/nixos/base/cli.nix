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
      zsh.enable = true;

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

      # for fugit2
      nix-ld.libraries = with pkgs; [ libgit2 ];
    };

    environment = {
      shellAliases = let
        nr = "nh os";
        hm = "nh home";
      in rec {
        ls = "eza";
        la = "${ls} -al";
        ll = "${ls} -l";
        l = "${ls} -l";

        mkd = "mkdir -pv";
        mv = "mv -v";
        rm = "rm -i";

        vim = "tu";
        vi = vim;
        v = vim;

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
        curl
        eza
        fd
        ffmpeg
        file
        fzf
        gcc
        gh
        git
        home-manager
        htop
        jq
        killall
        lsb-release
        mcfly
        mediainfo
        most
        neofetch
        nh
        openssl
        procps
        ps_mem
        rclone
        ripgrep
        tealdeer
        tmux
        wget
        yadm
        zoxide
      ];

      pathsToLink = [ "/share/zsh" ];
    };
  };
}
