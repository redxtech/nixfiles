{ inputs, self, ... }:

{
  den.aspects.git.homeManager =
    { config, pkgs, ... }:
    {
      home.packages = with pkgs; [
        delta # better git diffs
        git-filter-repo # rewrite git history
        git-lfs # large file storage
      ];

      programs.git = {
        enable = true;

        settings = {
          user.name = "Gabe Dunn";
          user.email = "gabe@gabedunn.dev";

          alias = {
            last = "log -1 --stat";
            cp = "cherry-pick";
            co = "checkout";
            cl = "clone";
            ci = "commit";
            st = "status -sb";
            br = "branch";
            unstage = "reset HEAD --";
            dc = "diff --cached";
            lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %Cblue<%an>%Creset' --abbrev-commit --date=relative --all";
            pop = "stash pop";
            s = "status";
            d = "diff";
            ds = "diff --staged";
            c = "commit";
            p = "push";
            r = "remote -v";
          };

          core = {
            autocrlf = "input";
            trustctime = false;
            editor = "tu";
            filemode = false;
          };

          color.ui = true;

          filter.lfs = {
            clean = "git-lfs clean -- %f";
            smudge = "git-lfs smudge -- %f";
            process = "git-lfs filter-process";
            required = true;
          };

          hub.protocol = "ssh";
          init.defaultBranch = "main";
          pull.rebase = true;
          push.default = "matching";
          tag.forceSignAnnotated = true;

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

        signing = {
          signByDefault = true;
          key = "1FBF2D806C456BB6";
        };

        includes = [ { path = "${config.xdg.configHome}/git/gitconfig.local"; } ];
      };

      programs.difftastic = {
        enable = true;
        git.enable = true;
        options.background = "dark";
      };

      programs.gh = {
        enable = true;

        extensions = with pkgs; [
          gh-cal
          gh-eco
          gh-markdown-preview
        ];

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

      programs.gitui = {
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

      programs.lazygit = {
        enable = true;
        settings = {
          gui = {
            nerdFontsVersion = "3";
          };
          disableStartupPopups = true;
        };
      };

      # programs.gh-dash.enable = true;
      # programs.git-cliff.enable = true;
      # programs.jujutsu.enable = true;
    };
}
