{ pkgs, ... }: {
  imports = [
    # ./fish.nix
    ./git.nix
    ./gpg.nix
    # ./jujutsu.nix
    # ./lyrics.nix
    ./neovim.nix
    ./nix-index.nix
    ./programs.nix
    ./services.nix
    ./ssh.nix
    ./zsh.nix
  ];

  home = {
    packages = with pkgs; [
      comma # install and run programs by sticking a , before them
      distrobox # nice escape hatch, integrates docker images with my environment

      age # encryption
      atool # work with archives
      bitwarden-cli # password manager
      bluetuith # bluetooth manager
      cachix # nix binary cache manager
      cpustat # cpu usage
      # delta # better diff
      dex # desktop entry executor
      diffsitter # better diff
      du-dust # better du
      dua # better du
      fd # better find
      fx # better jq
      figlet # ascii art
      ffmpeg # media multitool
      ffmpegthumbnailer # thumbnailer
      httpie # better curl
      # ltex-ls # spell checking LSP
      lsb-release # get distro info
      mediainfo # media info
      micro # editor
      neofetch # system info
      nil # nix LSP
      nixd # nix LSP
      nixfmt # nix formatter
      nix-du # du for nix store
      nix-inspect # see which pkgs are in your PATH
      pfetch # system info
      pipes-rs # pipes screensaver
      playerctl # media player controller
      # poetry # python package manager
      prettyping # better ping
      ps_mem # memory usage
      rage # age with rust
      ranger # file manager
      rclone # cloud storage manager
      rsync # file transfer
      sd # better sed
      slurm-nm # network monitor
      timer # to help with my ADHD paralysis
      tly # tally counter
      tokei # count lines of code in project
      urlencode # url encoder
      xclip # clipboard manager
      xdg-utils # xdg-open
      xdo # xdotool
      xfce.exo # protocol handler
      xorg.xmodmap # keyboard remapper
      yadm # dotfile manager
      yq-go # jq for yaml

      # personal packages
      switchup

      # TODO: move these to their own file OR specific dev shells
      google-cloud-sdk
      kubecolor
      kubectl
      kubectx
      telepresence2

      # get rid of or figure better place
      sqlite # for mcfly

      # languages
      nodejs
      (python3.withPackages (ps: with ps; [ dbus-python pygobject3 requests ]))
    ];

    shellAliases = {
      # ls = "eza";
      la = "ls -al";
      ll = "ls -l";
      l = "ls -l";

      mkd = "mkdir -pv";
      mv = "mv -v";
      rm = "rm -i";

      svim = "sudo -e";

      grep = "grep --color=auto";
      diff = "diff --color=auto";
      ip = "ip --color=auto";
    };

    # pfetch
    sessionVariables.PF_INFO =
      "ascii title os kernel uptime shell term desktop scheme palette";
  };

  programs = {
    bash = { enable = true; };

    bat = {
      enable = true;
      config.theme = "Dracula";
      # config.theme = "base16";
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    thefuck = {
      enable = true;
      # enableInstantMode = true;
    };

    mcfly = {
      enable = true;

      keyScheme = "vim";
    };

    zoxide.enable = true;
  };

}
