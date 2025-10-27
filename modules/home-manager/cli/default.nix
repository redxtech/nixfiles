{ config, inputs, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  imports = [
    ./config
    ./fish.nix
    ./git.nix
    ./gpg.nix
    ./langs.nix
    ./neovim.nix
    ./nix-index.nix
    ./programs.nix
    ./ranger
    ./services.nix
    ./starship.nix
    ./ssh.nix
    ./yazi.nix
    ./zsh.nix
  ];

  options.cli = let inherit (lib) mkOption;
  in with lib.types; {
    enable = lib.mkEnableOption "Enable desktop configuration";

    packages = mkOption {
      type = listOf package;
      default = [ ];
      description = "CLI packages to include";
    };

    aliases = mkOption {
      type = attrsOf str;
      default = { };
      description = "Shell aliases";
      example = {
        ls = "eza";
        la = "eza -la";
      };
    };

    env = mkOption {
      type = attrsOf str;
      default = { };
      description = "Environment variables";
      example = { ENV_VARIABLES = "values"; };
    };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs;
        [
          age # encryption
          ani-cli # anime tool
          appimage-run # run appimages
          atool # work with archives
          bitwarden-cli # password manager
          bluetuith # bluetooth manager
          bottom # top alternative
          cachix # nix binary cache manager
          catdoc # doc to text
          comma # install and run programs by sticking a , before them
          cowsay # ascii art
          cpufetch # cpu info
          inputs.deploy-rs.packages.${system}.deploy-rs # remote deploy
          dex # desktop entry executor
          dig # dns utils
          diffsitter # better diff
          distrobox # nice escape hatch, integrates docker images with my environment
          dogdns # better dig
          du-dust # better du
          dua # better du
          ente-cli # manage ente from cli
          espflash # esp flashing tool
          esptool # esp flashing tool
          fd # better find
          ffmpeg # media multitool
          ffmpegthumbnailer # thumbnailer
          ffsend # file sharing
          inputs.fh.packages.${system}.fh # flakehub
          figlet # ascii art
          flatpak # flatpak manager
          frogmouth # markdown reader
          fusee-nano # switch rcm loader
          fx # better jq
          gallery-dl # image downloader
          glxinfo # opengl info
          hci # hercules ci tool
          home-assistant-cli # home assistant cli
          httpie # better curl
          hyfetch # neofetch fork
          kdePackages.kwallet # kde secrets manager
          libnotify # desktop notifications
          libsecret # secrets manager
          libwebp # webp support
          # ltex-ls # spell checking LSP
          lsb-release # get distro info
          lsof # list open files
          lshw # hardware info
          manix # nix documentation tool
          mediainfo # media info
          megatools # mega.io cli
          micro # editor
          most # pager
          neofetch # system info
          nixfmt-classic # nix formatter
          nixpkgs-review # nixpkgs PR reviewer
          nix-autobahn # dynamic executable helper
          nix-du # du for nix store
          nix-inspect # see which pkgs are in your PATH
          nix-update # update hashes in nix files
          omnix # better cli for nix
          onefetch # current repo info
          pciutils # pci info
          pfetch-rs # system info
          pipes-rs # pipes screensaver
          playerctl # media player controller
          # poetry # python package manager
          prettyping # better ping
          p7zip # zip archiver
          rage # age with rust
          ramfetch # system info
          rclone # cloud storage manager
          rsync # file transfer
          sad # space age sed
          sd # better sed
          sops # secrets manager
          sshfs # mount remote filesystems
          steam-run # run binaries in fhs
          streamrip # download music
          sl # teehee
          slurm-nm # network monitor
          timg # in-terminal image viewer
          todoist # todo app client
          tokei # count lines of code in project
          trashy # trash manager
          urlencode # url encoder
          unrar # unarchiver
          unzip # unarchiver
          xclip # clipboard manager
          xdg-utils # for xdg-open
          xdo # xdotool
          xfce.exo # protocol handler
          xorg.xev # keyboard event viewer
          xorg.xmodmap # keyboard remapper
          yadm # dotfile manager
          yq-go # jq for yaml
          vcs # video contact sheet
          vulnix # nix security checker
          zip # archiver

          # personal packages
          switchup

          # k8s packages
          kubectl
          kubectl-cnpg
          kubecolor
          kubectx
          kubeseal
          # telepresence2
        ] ++ cfg.packages;

      shellAliases = let
        hasPackage = pname:
          lib.any (p: p ? pname && p.pname == pname) config.home.packages;
        hasRipgrep = hasPackage "ripgrep";
        hasNeovim = config.programs.neovim.enable;
      in rec {
        # main aliaes
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
        svim = "sudo -e";
        nrt = "nix run $HOME/Code/nvim/tu";

        grep = "grep --color=auto";
        diff = "diff --color=auto";
        ip = "ip --color=auto";

        src = "exec $SHELL";

        # nix
        n = "nix-shell -p";
        nb = "nix build";
        # nd = "nix develop -c $SHELL";
        ndi = "nix develop --impure -c $SHELL";
        ns = "nix shell";
        nf = "nix flake";

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
        dua = mkIf (hasPackage "dua") "dua interactive";
        kubectl = mkIf (hasPackage "kubecolor") "kubecolor";
        ping = mkIf (hasPackage "prettyping") "prettyping";
        pipes = mkIf (hasPackage "pipes-rs") "piipes-rs";

        # general aliaes
        cik = "clone-in-kitty --type os-window";
        ck = cik;
        deploy = "deploy -s";
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
        npr = "npm run";
        ps_mem = "sudo ps_mem";
        rcp = "rclone copy -P --transfers=20";
        rgu = "rg -uu";
        rsync = "rsync --info=progress2 -r";
        shit = "sudo $(fc -ln -1)";
        todoist = mkIf (hasPackage "todoist") "todoist --color";
        xclip = "xclip -selection c";
        yt-dlp-docker = let image = "docker.io/bxggs/yt-dlp";
        in "docker run -it --rm -v ./:/data ${image}";
        vrg = mkIf (hasNeovim && hasRipgrep) "nvimrg";

        # fun
        expand-dong = "aunpack";
        starwars = "telnet towel.blinkenlights.nl";
      } // cfg.aliases;

      sessionVariables = {
        DIRENV_LOG_FORMAT = "";
        ENTE_CLI_CONFIG_PATH = "${config.xdg.configHome}/ente/config.yaml";
        FFSEND_HOST = "send.super.fish";
        KUBECONFIG = "${config.xdg.configHome}/kube/config";
        PF_INFO =
          "ascii title os kernel uptime shell term desktop scheme palette";
        PNPM_HOME = "${config.xdg.dataHome}/pnpm";
      } // cfg.env;
    };

    programs = {
      bash.enable = true;

      pay-respects = {
        enable = true;
        enableFishIntegration = true;
      };

      mcfly = {
        enable = true;
        keyScheme = "vim";
      };

      zoxide.enable = true;
    };
  };
}

