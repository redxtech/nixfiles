{ pkgs, ... }: {
  imports = [
    # ./fish.nix
    ./git.nix
    ./gpg.nix
    # ./jujutsu.nix
    # ./lyrics.nix
    ./nix-index.nix
    ./ssh.nix
    ./zsh.nix
  ];

  home = {
    # TODO: remove programs installed by programs.<program>
    packages = with pkgs; [
      comma # install and run programs by sticking a , before them
      distrobox # nice escape hatch, integrates docker images with my environment

      atool # work with archives
      bat # better cat
      btop # better top
      cpustat # cpu usage
      delta # better diff
      dex # desktop entry executor
      eza # better ls
      fd # better find
      figlet # ascii art
      ffmpeg # media multitool
      ffmpegthumbnailer # thumbnailer
      # fnm
      fzf # fuzzy finder
      gh # github cli
      git # version control
      httpie # better curl
      hub # github cli
      lazygit # git ui
      ltex-ls # spell checking LSP
      mcfly # better history
      mediainfo # media info
      micro # editor
      neofetch # system info
      nil # nix LSP
      nixfmt # nix formatter
      nix-inspect # see which pkgs are in your PATH
      pfetch # system info
      playerctl # media player controller
      # poetry # python package manager
      ranger # file manager
      rclone # cloud storage manager
      ripgrep # better grep
      tealdeer # better man pages
      tly # tally counter
      tmux # terminal multiplexer
      diffsitter # better diff
      jq # JSON pretty printer and manipulator
      timer # to help with my ADHD paralysis
      # urlencode # url encoder
      xdo # xdotool
      xfce.exo # protocol handler
      xorg.xmodmap # keyboard remapper
      yadm # dotfile manager
      yt-dlp # youtube downloader
      zoxide # better cd
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
