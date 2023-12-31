{ pkgs, lib, config, ... }:
let
  inherit (lib) mkIf;
  hasPackage = pname:
    lib.any (p: p ? pname && p.pname == pname) config.home.packages;
  hasRipgrep = hasPackage "ripgrep";
  hasExa = hasPackage "eza";
  hasNeovim = config.programs.neovim.enable;
  hasShellColor = config.programs.shellcolor.enable;
  hasKitty = config.programs.kitty.enable;
  shellcolor = "${pkgs.shellcolord}/bin/shellcolor";
in {
  programs.zsh = {
    enable = true;

    enableAutosuggestions = true;
    enableCompletion = true;

    autocd = true;
    defaultKeymap = "viins";
    dotDir = ".config/zsh";

    history = {
      expireDuplicatesFirst = true;
      extended = true;
      ignoreAllDups = false;
      ignoreDups = true;
      ignoreSpace = true;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
      share = true;
      save = 100000;
    };

    dirHashes = {
      code = "$HOME/Code";
      dl = "$HOME/Downloads";
      docs = "$HOME/Documents";
      drawer = "$HOME/Drawer";
      pics = "$HOME/Pictures";
      vids = "$HOME/Videos";
    };

    zsh-abbr = {
      enable = true;

      abbreviations = {
        nsn = "nix shell nixpkgs#";
        nbn = "nix build nixpkgs#";

        yamd = "yadm";
        yand = "yadm";

        ecoh = "echo";
        pacuar = "pacaur";
        sudp = "sudo";
        yarm = "yarn";
        clera = "clear";
        claer = "clear";
        dc = "cd";
      };
    };

    initExtraFirst = ''
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi
    '';

    initExtra = ''
      # more zsh options
      setopt append_history             # each shell adds its history on exit
      setopt extended_glob              # include #, ^, & ~ in globbing
      setopt hist_reduce_blanks         # remove unnecessary spaces
      setopt no_correct                 # don't do corrections
      setopt notify                     # show backgrounded jobs immediately
      setopt prompt_subst               # expand functions in prompt
      setopt transient_rprompt          # don't include right prompt in history 
      setopt function_arg_zero          # set $0 for each function, script, etc
      setopt function_arg_zero          # set $0 for each function, script, etc
      setopt no_menu_complete           # autocomplete menu

      # hyphen & case insensitive completions 
      zstyle ':completion:*' matcher-list "" 'm:{a-zA-Z-_}={A-Za-z_-}'

      # kubecolor completion
      compdef kubecolor=kubectl

      # source the theme
      [[ ! -f "$ZSH_CUSTOM/p10k.zsh" ]] || source "$ZSH_CUSTOM/p10k.zsh"

      if test -f ${config.xdg.configHome}/zsh/env.local.zsh; then
        source ${config.xdg.configHome}/zsh/env.local.zsh
      fi

      if test -f ${config.xdg.configHome}/zsh/env.secrets.zsh; then
        source ${config.xdg.configHome}/zsh/env.secrets.zsh
      fi
    '';

    sessionVariables = {
      ZSH_CUSTOM = "${config.xdg.configHome}/zsh";
      ZSH_FNM_ENV_EXTRA_ARGS = "--use-on-cd";
      AUTO_NOTIFY_EXPIRE_TIME = 10000;
      AUTO_NOTIFY_IGNORE =
        "(btm btop conf docker kitty micro ranger spotifyd spt tmux yadm zsh)";
      KUBECONFIG = "${config.xdg.configHome}/kube/config";
      PNPM_HOME = "${config.xdg.dataHome}/pnpm";
      RANGER_LOAD_DEFAULT_RC = "FALSE";
    };

    shellAliases = rec {
      jqless = "jq -C | less -r";

      n = "nix";
      np = "${n}-shell -p";
      nd = "${n} develop -c $SHELL";
      ns = "${n} shell";
      nb = "${n} build";
      nbp =
        "nix-build -E 'with import <nixpkgs> {}; callPackage ./default.nix {}'";
      nf = "${n} flake";

      hm = "home-manager --flake .";
      hms = "${hm} switch";
      hmsb = "${hms} -b backup";
      hmb = "${hm} build";
      hmn = "${hm} news";

      cik = "clone-in-kitty --type os-window";
      ck = cik;

      ly =
        "lazygit --git-dir=$HOME/.local/share/yadm/repo.git --work-tree=$HOME";

      src = "exec $SHELL";
      shit = "sudo $(fc -ln -1)";

      ssh = mkIf hasKitty "kitty +kitten ssh";
      cat = mkIf (hasPackage "bat") "bat";
      dia = mkIf (hasPackage "dua") "dua interactive";
      ping = mkIf (hasPackage "prettyping") "prettyping";
      pipes = mkIf (hasPackage "pipes-rs") "piipes-rs";

      jc = "journalctl -xeu";
      jcu = "journalctl --user -xeu";

      npr = "npm run";
      rsync = "rsync --info=progress2 -r";
      rcp = "rclone copy -P --transfers=20";
      xclip = "xclip -selection c";
      ps_mem = "sudo ps_mem";
      neofetchk = "neofetch --backend kitty --source $HOME/.config/wall.png";
      "inodes-where" =
        "sudo du --inodes --separate-dirs --one-file-system / | sort -rh | head";
      dirties = "watch -d grep -e Dirty: -e Writeback: /proc/meminfo";
      expand-dong = "aunpack";

      starwars = "telnet towel.blinkenlights.nl";

      # Clear screen and scrollback
      # clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    };

    zplug = {
      enable = true;
      zplugHome = "${config.xdg.dataHome}/zplug";

      plugins = let
        tags = rec {
          early = [ "defer:1" ];
          late = [ "defer:2" ];
          end = [ "defer:3" ];
          ghr = [ "from:gh-r" ];
          omz = [ "from:oh-my-zsh" ];
          archOnly = [ ''if:"command -v pacman >/dev/null"'' ];
          nixOnly = [ ''if:"command -v nixos-rebuild >/dev/null"'' ];
          dnfOnly = [ ''if:"command -v dnf >/dev/null"'' ];
          aptOnly = [ ''if:"command -v apt >/dev/null"'' ];
        };
      in [
        {
          name = "romkatv/powerlevel10k";
          tags = [ "as:theme" ];
        }
        {
          name = "Aloxaf/fzf-tab";
          tags = [ ];
        }
        {
          name = "ael-code/zsh-colored-man-pages";
          tags = tags.early;
        }
        {
          name = "chisui/zsh-nix-shell";
          tags = [ ];
        }
        {
          name = "dominik-schwabe/zsh-fnm";
          tags = tags.early ++ tags.archOnly;
        }
        {
          name = "g-plane/zsh-yarn-autocompletions";
          tags = tags.early;
        }
        {
          name = "greymd/docker-zsh-completion";
          tags = tags.early;
        }
        {
          name = "hlissner/zsh-autopair";
          tags = [ ];
        }
        {
          name = "MichaelAquilina/zsh-auto-notify";
          tags = tags.early
            ++ [ ''if:"[ test command -v notify-send >/dev/null ]"'' ];
        }
        {
          name = "nix-community/nix-zsh-completions";
          tags = [ ];
        }
        {
          name = "plugins/archlinux";
          tags = tags.archOnly ++ tags.omz;
        }
        {
          name = "plugins/dnf";
          tags = tags.dnfOnly ++ tags.omz;
        }
        {
          name = "plugins/ubuntu";
          tags = tags.aptOnly ++ tags.omz;
        }
        {
          name = "plugins/command-not-found";
          tags = tags.omz;
        }
        {
          name = "plugins/github";
          tags = tags.omz;
        }
        {
          name = "plugins/man";
          tags = tags.omz;
        }
        {
          name = "plugins/transfer";
          tags = tags.early ++ tags.omz;
        }
        {
          name = "redxtech/zsh-containers";
          tags = tags.early;
        }
        {
          name = "redxtech/zsh-kitty";
          tags = tags.late;
        }
        {
          name = "redxtech/zsh-not-vim";
          tags = tags.early;
        }
        {
          name = "redxtech/zsh-show-path";
          tags = tags.early;
        }
        {
          name = "redxtech/zsh-systemd";
          tags = tags.early;
        }
        {
          name = "redxtech/zsh-unix-simple";
          tags = tags.early;
        }
        {
          name = "ryutok/rust-zsh-completions";
          tags = tags.early;
        }
        {
          name = "voronkovich/gitignore.plugin.zsh";
          tags = tags.early;
        }
        {
          name = "zdharma-continuum/fast-syntax-highlighting";
          tags = [ ];
        }
        {
          name = "zpm-zsh/ssh";
          tags = tags.early;
        }
        {
          name = "zsh-users/zsh-completions";
          tags = tags.late;
        }
      ];
    };
  };

  # file writing
  xdg.configFile."zsh/env.secrets.zsh".text = ''
    export YOUTUBE_API_KEY="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.youtube.path})"
    export BW_SESSION="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.bw.path})"
  '';
}
