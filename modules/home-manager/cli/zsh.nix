{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;

  hasPackage = pname:
    lib.any (p: p ? pname && p.pname == pname) config.home.packages;
  hasKitty = config.programs.kitty.enable;
in {
  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;

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
          "(btm btop conf docker kitty micro ranger spotifyd spt ssh tmux yadm zsh)";
      };

      shellAliases = rec { shit = "sudo $(fc -ln -1)"; };

      zinit = {
        enable = true;

        enableSyntaxCompletionsSuggestions = true;

        plugins = [
          { name = "aloxaf/fzf-tab"; }
          { name = "ael-code/zsh-colored-man-pages"; }
          { name = "chisui/zsh-nix-shell"; }
          {
            name = "g-plane/zsh-yarn-autocompletions";
            ice = {
              atload = "zpcdreplay";
              atclone = "zsh ./zplug.zsh";
            };
          }
          { name = "greymd/docker-zsh-completion"; }
          { name = "hlissner/zsh-autopair"; }
          { name = "MichaelAquilina/zsh-auto-notify"; }
          {
            name = "nix-community/nix-zsh-completions";
          }
          # {
          #   name = "OMZP::archlinux";
          #   tags = tags.archOnly;
          # }
          # {
          #   name = "OMZP::dnf";
          #   tags = tags.dnfOnly;
          # }
          # {
          #   name = "OMZP::ubuntu";
          #   tags = tags.aptOnly;
          # }
          {
            name = "OMZP::command-not-found";
            snippet = true;
          }
          {
            name = "OMZP::github";
            snippet = true;
          }
          {
            name = "OMZP::man";
            snippet = true;
          }
          {
            name = "OMZP::transfer";
            snippet = true;
          }
          { name = "redxtech/zsh-containers"; }
          {
            name = "redxtech/zsh-kitty";
            ice = {
              wait = "2";
              atload = "__kitty_complete";
            };
          }
          { name = "redxtech/zsh-not-vim"; }
          { name = "redxtech/zsh-show-path"; }
          { name = "redxtech/zsh-systemd"; }
          { name = "redxtech/zsh-unix-simple"; }
          {
            name = "ryutok/rust-zsh-completions";
            ice = { as = "completion"; };
          }
          { name = "voronkovich/gitignore.plugin.zsh"; }
          { name = "zpm-zsh/ssh"; }
        ];
      };
    };

    # file writing
    xdg.configFile."zsh/env.secrets.zsh".text = ''
      export YOUTUBE_API_KEY="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.youtube.path})"
      export BW_SESSION="$(${pkgs.coreutils}/bin/cat ${config.sops.secrets.bw.path})"
    '';
  };
}
