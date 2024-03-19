{ pkgs, lib, config, ... }:

with lib; {
  imports = [
    ./config
    ./fish.nix
    ./git.nix
    ./gpg.nix
    # ./jujutsu.nix
    # ./lyrics.nix
    ./neovim.nix
    ./nix-index.nix
    ./programs.nix
    ./services.nix
    ./starship.nix
    ./ssh.nix
    ./zsh.nix
  ];

  home = {
    packages = with pkgs; [
      comma # install and run programs by sticking a , before them
      distrobox # nice escape hatch, integrates docker images with my environment

      adguardian # monitor adguard home
      age # encryption
      atool # work with archives
      bitwarden-cli # password manager
      bluetuith # bluetooth manager
      cachix # nix binary cache manager
      cowsay # ascii art
      cpustat # cpu usage
      # delta # better diff
      dex # desktop entry executor
      diffsitter # better diff
      dogdns # better dig
      du-dust # better du
      dua # better du
      fd # better find
      frogmouth # markdown reader
      fx # better jq
      figlet # ascii art
      ffmpeg # media multitool
      ffmpegthumbnailer # thumbnailer
      gallery-dl # image downloader
      httpie # better curl
      libnotify # desktop notifications
      libwebp # webp support
      # ltex-ls # spell checking LSP
      lsb-release # get distro info
      lyrics # lyrics in terminal
      manix # nix documentation tool
      mediainfo # media info
      micro # editor
      navi # cheatsheet
      neofetch # system info
      nil # nix LSP
      nixd # nix LSP
      nixfmt # nix formatter
      # nix-delegate # distributed nix builds transparently
      nix-autobahn # dynamic executable helper
      nix-du # du for nix store
      nix-inspect # see which pkgs are in your PATH
      packagekit # package helper across distros
      pfetch # system info
      piper # gui for ratbagd
      pipes-rs # pipes screensaver
      playerctl # media player controller
      # poetry # python package manager
      prettyping # better ping
      p7zip # zip archiver
      rage # age with rust
      ranger # file manager
      rclone # cloud storage manager
      rsync # file transfer
      sd # better sed
      sshfs # mount remote filesystems
      steam-run # run binaries in fhs
      slurm-nm # network monitor
      timer # to help with my ADHD paralysis
      todoist # todo app client
      tokei # count lines of code in project
      urlencode # url encoder
      xclip # clipboard manager
      xdg-utils # xdg-open
      xdo # xdotool
      xfce.exo # protocol handler
      xorg.xev # keyboard event viewer
      xorg.xmodmap # keyboard remapper
      yadm # dotfile manager
      yq-go # jq for yaml
      ventoy # bootable usb creator
      vulnix # nix security checker
      zip # archiver

      # flakehub
      fh

      # personal packages
      switchup

      # TODO: move these to their own file OR specific dev shells
      (google-cloud-sdk.withExtraComponents
        [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
      kubecolor
      kubectl
      kubectx
      telepresence2
    ];

    shellAliases = let
      inherit (lib) mkIf;
      hasPackage = pname:
        lib.any (p: p ? pname && p.pname == pname) config.home.packages;
      hasRipgrep = hasPackage "ripgrep";
      hasExa = hasPackage "eza";
      hasNeovim = config.programs.neovim.enable;
      hasKitty = config.programs.kitty.enable;
    in rec {
      # main aliaes
      ls = "eza";
      la = "${ls} -al";
      ll = "${ls} -l";
      l = "${ls} -l";

      mkd = "mkdir -pv";
      mv = "mv -v";
      rm = "rm -i";

      vim = "nvim";
      vi = vim;
      v = vim;
      svim = "sudo -e";

      grep = "grep --color=auto";
      diff = "diff --color=auto";
      ip = "ip --color=auto";

      src = "exec $SHELL";

      # nix
      n = "nix-shell -p";
      nb = "nix build";
      # nd = "nix develop -c $SHELL";
      ns = "nix shell";
      nf = "nix flake";
      flakeup =
        "nix flake update --update-input nixpkgs --update-input home-manager";

      # build nixos iso file
      nbsiso = "nix build .#nixosConfigurations.nixiso.config.formats.iso";

      # home manager
      hm = "home-manager --flake $FLAKE";
      hmsb = "${hm} switch -b backup";
      hmb = "${hm} build";
      hmn = "${hm} news";

      hms = "${pkgs.nh}/bin/nh home switch";

      # replacements
      cat = mkIf (hasPackage "bat") "bat";
      dia = mkIf (hasPackage "dua") "dua interactive";
      kubectl = mkIf (hasPackage "kubecolor") "kubecolor";
      ping = mkIf (hasPackage "prettyping") "prettyping";
      pipes = mkIf (hasPackage "pipes-rs") "piipes-rs";
      ssh = mkIf hasKitty "kitty +kitten ssh";

      # general aliaes
      cik = "clone-in-kitty --type os-window";
      ck = cik;
      dirties = "watch -d grep -e Dirty: -e Writeback: /proc/meminfo";
      jc = "journalctl -xeu";
      jcu = "journalctl --user -xeu";
      jqless = "jq -C | less -r";
      ly =
        "lazygit --git-dir=$HOME/.local/share/yadm/repo.git --work-tree=$HOME";
      md = "frogmouth";
      neofetchk = "neofetch --backend kitty --source $HOME/.config/wall.png";
      "inodes-where" =
        "sudo du --inodes --separate-dirs --one-file-system / | sort -rh | head";
      ps_mem = "sudo ps_mem";
      rcp = "rclone copy -P --transfers=20";
      rgu = "rg -uu";
      rsync = "rsync --info=progress2 -r";
      xclip = "xclip -selection c";
      vrg = mkIf (hasNeovim && hasRipgrep) "nvimrg";

      # fun
      expand-dong = "aunpack";
      starwars = "telnet towel.blinkenlights.nl";
    };

    sessionVariables = {
      DIRENV_LOG_FORMAT = "";
      KUBECONFIG = "${config.xdg.configHome}/kube/config";
      PF_INFO =
        "ascii title os kernel uptime shell term desktop scheme palette";
      RANGER_LOAD_DEFAULT_RC = "FALSE";
    };
  };

  programs = {
    bash = { enable = true; };

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
