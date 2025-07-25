{ pkgs, lib, config, ... }:

let cfg = config.cli;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      delta # better git diffs
      git-crypt # encrypt files in git
      git-filter-repo # rewrite git history
      git-lfs # large file storage
      transcrypt # encrypt files in git
    ];

    programs = {
      git = {
        enable = true;

        package = pkgs.hub;

        userName = "Gabe Dunn";
        userEmail = "gabe@gabedunn.dev";

        aliases = {
          last = "log -1 --stat";
          cp = "cherry-pick";
          co = "checkout";
          cl = "clone";
          ci = "commit";
          st = "status -sb";
          br = "branch";
          unstage = "reset HEAD --";
          dc = "diff --cached";
          lg =
            "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %Cblue<%an>%Creset' --abbrev-commit --date=relative --all";
          pop = "stash pop";
          s = "status";
          d = "diff";
          ds = "diff --staged";
          c = "commit";
          p = "push";
          r = "remote -v";
        };

        signing = {
          signByDefault = true;
          key = "1FBF2D806C456BB6";
        };

        extraConfig = {
          core = {
            autocrlf = "input";
            trustctime = false;
            editor = "tu";
            filemode = false;
          };
          color = { ui = true; };
          filter.lfs = {
            clean = "git-lfs clean -- %f";
            smudge = "git-lfs smudge -- %f";
            process = "git-lfs filter-process";
            required = true;
          };
          hub = { protocol = "ssh"; };
          init = { defaultBranch = "master"; };
          pull = { rebase = true; };
          push = { default = "matching"; };
          tag = { forceSignAnnotated = true; };
          # merge = { tool = "nvim -d"; };
          # mergetool = {
          #   keeptemporaries = false;
          #   keepbackups = false;
          #   prompt = false;
          #   trustexitcode = false;
          #   path = "nvim -d";
          # };
          # pager = {
          #   diff = "delta";
          #   log = "delta";
          #   reflog = "delta";
          #   show = "delta";
          # };
        };

        includes = [{ path = "${config.xdg.configHome}/git/gitconfig.local"; }];

        difftastic = {
          enable = true;

          background = "dark";
          # display = "inline";
        };

        delta = {
          enable = false;

          options = {
            features = "side-by-side line-numbers decorations";
            # TODO: fix these getting formatted improperly
            # plus_style = "syntax #003800";
            # minus_style = "syntax #3f0001";
            navigate = true;
            decorations = {
              commit-decoration-style = "bold yellow box ul";
              file-style = "bold yellow ul";
              file-decoration-style = "none";
              hunk-header-decoration-style = "cyan box ul";
            };
            line-numbers = {
              line-numbers-left-style = "cyan";
              line-numbers-right-style = "cyan";
              line-numbers-minus-style = 124;
              line-numbers-plus-style = 28;
            };
          };
        };
      };

      gh = {
        enable = true;

        extensions = with pkgs; [ gh-cal gh-eco gh-markdown-preview ];

        settings = {
          git_protocol = "ssh";

          prompt = "enabled";

          aliases = {
            co = "pr checkout";
            pv = "pr view";
          };
          version = 1;
        };
      };

      gh-dash.enable = true;

      git-cliff = { enable = true; };

      gitui = {
        enable = false;
        keyConfig = ''
          move_left: Some(( code: Char('h'), modifiers: ( bits: 0,),)),
          move_right: Some(( code: Char('l'), modifiers: ( bits: 0,),)),
          move_up: Some(( code: Char('k'), modifiers: ( bits: 0,),)),
          move_down: Some(( code: Char('j'), modifiers: ( bits: 0,),)),

          stash_open: Some(( code: Char('l'), modifiers: ( bits: 0,),)),

          open_help: Some(( code: F(1), modifiers: ( bits: 0,),)),
        '';
      };

      lazygit = {
        enable = true;
        settings = {
          gui = { nerdFontsVersion = "3"; };
          disableStartupPopups = true;
        };
      };

      jujutsu = {
        enable = true;
        settings = {
          user = {
            name = config.programs.git.userName;
            email = config.programs.git.userEmail;
          };
        };
      };
    };
  };
}
