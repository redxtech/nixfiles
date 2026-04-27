{ den, ... }:

{
  den.aspects.cli = {
    includes = [
      den.aspects.cli-config
      den.aspects.editor
      den.aspects.fish-shell
      den.aspects.git
      den.aspects.gpg
      den.aspects.multiplexer
      den.aspects.nix-index
      den.aspects.prompt
      den.aspects.yazi
    ];

    # TODO: add more cli aspects

    # - pyenv # TODO: move to dev aspect
    # - sftpman
    # - ssh

    nixos =
      { config, pkgs, ... }:
      {
        # fish enables this, but it takes so long to build so i'm disabling it
        documentation.man.cache.enable = false;

        programs.bat = {
          enable = true;
          settings.theme = "Dracula";
        };

        programs.fish.useBabelfish = true;

        programs.git.enable = true;
        programs.htop.enable = true;
        programs.tmux.enable = true;

        environment = {
          shellAliases = rec {
            ls = "eza --group-directories-first";
            la = "${ls} -la";
            ll = "${ls} -l";
            l = "${ls} -l";

            mkd = "mkdir -pv";
            mv = "mv -v";
            rm = "rm -i";

            vim = "tu";
            vi = vim;
            v = vim;

            nrs = "nh os switch";
            nru = "${nrs} --ask --update";
            snrs = "sudo nixos-rebuild --flake $FLAKE switch";

            hms = "nh home switch";
            hmsu = "${hms} --ask --update";
            hmsb = "${hms} -b backup";
          };

          systemPackages = with pkgs; [
            btop
            curl
            eza
            fastfetch
            fd
            file
            jq
            killall
            mediainfo
            openssl
            procps
            ps_mem
            ripgrep
            rsync
            tealdeer
            wget
          ];
        };
      };

    homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        home = {
          packages = with pkgs; [
            # android-tools # adb
            # appimage-run
            atool # archive tools
            bitwarden-cli # password manager
            cachix # nix cache
            # catdoc # word docs -> text
            comma # run nix commands with ,
            cowsay # make a cow say something
            cpufetch # cpu info
            dex # desktop entry launcher
            dig # dns lookup
            distrobox # nice escape hatch, use docker to emulate other distros
            doggo # better dig
            dua # better du
            dust # better du
            ffmpeg-full # media tool # TODO: move to optional ??
            ffmpegthumbnailer # ffmpeg thumbnailer # TODO: move to GUI/file browser?
            ffsend # file sharing
            figlet # ascii art
            flatpak # flatpak manager
            frogmouth # markdown reader
            fusee-nano # switch rcm loader # TODO: move to desktop/laptop?
            # fx # better jq
            # gallery-dl # download images
            home-assistant-cli # home assistant cli
            hyfetch # neofetch fork
            libnotify # desktop notifications
            libsecret # secrets manager
            libwebp # webp support
            lsof # list open files
            lshw # hardware info
            manix # nix documentation tool
            mediainfo # media info
            micro # text editor
            nixpkgs-review # nixpkgs PR reviewer
            # nix-autobahn # dynamic executable runner tool # TODO: add from flake
            nix-du # du for the nix store
            nix-inspect # search nix store
            nix-update # update hashes in nix files
            # onefetch # current repo info
            pciutils # pci info
            pfetch-rs # tiny system info
            pipes-rs # screensaver util
            playerctl # media control # TODO: move to desktop
            prettyping # ping with pretty output
            p7zip # 7zip tool
            ramfetch # ram info
            rclone # cloud sync
            sd # better sed
            sqlite # sqlite cli (for mcfly)
            sops # secrets manager
            sshfs # mount ssh filesystems
            steam-run # run binaries in steam FHS
            # streamrip # download music
            sl # teehee
            tokei # code stats
            trashy # trash manager
            unrar # unarchiver
            unzip # unarchiver
            xdg-utils # for xdg-open
            xfce4-exo # protocol handler
            yq-go # jq for yaml
            zip # archiver

            # k8s packages
            # TODO: move to k8s aspect ??
            kubectl
            kubectl-cnpg
            kubecolor
            kubectx
            kubeseal
          ];

          shellAliases =
            let
              inherit (lib) mkIf;
              hasPackage = pname: lib.any (p: p ? pname && p.pname == pname) config.home.packages;
              hasRipgrep = hasPackage "ripgrep";
              hasNeovim = config.programs.neovim.enable;
            in
            rec {
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
              "inodes-where" = "sudo du --inodes --separate-dirs --one-file-system / | sort -rh | head";
              npr = "npm run";
              ps_mem = "sudo ps_mem";
              rcp = "rclone copy -P --transfers=20";
              rgu = "rg -uu";
              rsync = "rsync --info=progress2 -r";
              shit = "sudo $(fc -ln -1)";
              yt-dlp-docker = "docker run -it --rm -v ./:/data docker.io/bxggs/yt-dlp";
              vrg = mkIf (hasNeovim && hasRipgrep) "nvimrg";

              # fun
              expand-dong = "aunpack";
              starwars = "telnet towel.blinkenlights.nl";
            };

          sessionVariables = {
            DIRENV_LOG_FORMAT = "";
            ENTE_CLI_CONFIG_PATH = "${config.xdg.configHome}/ente/config.yaml";
            FFSEND_HOST = "send.super.fish";
            KUBECONFIG = "${config.xdg.configHome}/kube/config";
            PF_INFO = "ascii title os kernel uptime shell term desktop scheme palette";
            PNPM_HOME = "${config.xdg.dataHome}/pnpm";
          };
        };

        programs.atool.enable = true;
        programs.bat.enable = true;
        programs.bash.enable = true;
        programs.fd.enable = true;
        programs.home-manager.enable = true;
        programs.htop.enable = true;
        programs.jq.enable = true;
        programs.ripgrep.enable = true;
        programs.ripgrep-all.enable = true;
        programs.zoxide.enable = true;

        programs.btop = {
          enable = true;
          settings = {
            # color_theme = "dracula";
            theme_background = false;
            presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
            vim_keys = true;
            graph_symbol = "braille";
            shown_boxes = "cpu net proc mem";
            update_ms = 1500;
            proc_sorting = "cpu direct";
            proc_filter_kernel = true;
            disks_filter = "exclude=/boot";
            show_swap = false;
            swap_disk = false;
          };
        };

        programs.cava = {
          enable = true;
          settings = {
            general = {
              autosens = 1;
              bar_width = 3;
              framerate = 144;
              # overshoot = 20;
              # sensitivity = 100;
            };
            input = {
              source = "auto";
            };
            smoothing = {
              monstercat = 1; # TODO: test this
            };
          };
        };

        programs.direnv = {
          enable = true;

          enableZshIntegration = true;
          nix-direnv.enable = true;

          config.load_dotenv = true;
        };

        programs.eza = {
          enable = true;
          git = true;
          icons = "auto";
          extraOptions = [
            "--group-directories-first"
            "--header"
          ];
        };

        programs.fzf = {
          enable = true;
          tmux.enableShellIntegration = true;
        };

        programs.mcfly = {
          enable = true;
          keyScheme = "vim";
        };

        programs.pay-respects = {
          enable = true;
          enableFishIntegration = true;
        };

        programs.tealdeer = {
          enable = true;
          settings = {
            display.compact = false;
            updates = {
              auto_update = true;
              auto_update_interval_hours = 168;
            };
          };
        };

        programs.yt-dlp = {
          enable = true;

          settings = {
            output = "'[%(release_date>%Y-%m-%d,upload_date>%Y-%m-%d|Unknown)s] %(creator)s - %(title)s.%(ext)s'";
            # format = "best";
            concurrent-fragments = 5;
            write-thumbnail = true;
            audio-multistreams = true;
            prefer-free-formats = true;
            write-subs = true;
            remux-video = "mkv";
            embed-subs = true;
            embed-thumbnail = true;
            embed-metadata = true;
            embed-chapters = true;
            embed-info-json = true;
            sponsorblock-mark = "all";
          };
        };
      };
  };
}
