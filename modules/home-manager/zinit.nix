{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh.zinit;

  arglessIces = [
    "aliases"
    "blockf"
    "cloneonly"
    "completions"
    "countdown"
    "light-mode"
    "link"
    "lucid"
    "nocd"
    "nocompile"
    "nocompletions"
    "notify"
    "reset"
    "reset-prompt"
    "run-atpull"
    "service"
    "silent"
    "svn"
    "wait"

    "sh"
    "bash"
    "csh"
    "ksh"
  ];
  iceToStr = name: value:
    if (name == "wait" || name == "lucid") && value == "false" then
      ""
    else if name == "wait" && value != "0" then
      "wait'${value}'"
    else if builtins.elem name arglessIces then
      "${name}"
    else
      "${name}'${value}'";
  icesToStr = ices: concatStringsSep " " ices;
  defaultIces = {
    wait = "0";
    lucid = "true";
  };

  pluginModule = types.submodule ({ config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        description = "The name of the plugin.";
      };

      ice = mkOption {
        type = types.attrsOf types.str;
        default = {
          wait = "0";
          lucid = "true";
        };
        description = "Ices to apply to the plugin.";
      };
    };

  });

in {
  options.programs.zsh.zinit = {
    enable = mkEnableOption "zinit - flexible and fast zsh plugin manager";

    plugins = mkOption {
      default = [ ];
      type = types.listOf pluginModule;
      description = "List of zinit plugins.";
    };

    zinitHome = mkOption {
      type = types.path;
      default = "${config.xdg.dataHome}/zinit";
      defaultText = "~/.local/share/zinit";
      apply = toString;
      description = "Path to zinit home directory.";
    };

    # TODO: add more p10k options ?
    p10k.enable = mkEnableOption "p10k - powerlevel10k theme for zsh";

    enableSyntaxCompletionsSuggestions = mkEnableOption
      "Enable fast-syntax-highlighting, zsh-completions and zsh-autosuggestions.";
  };

  config = let isOMZP = str: builtins.substring 0 6 str == "OMZP::";
  in mkIf cfg.enable {
    home.packages = [ pkgs.zinit ];

    # TODO: split into only wait & lucid / other ices, and use for \
    programs.zsh.initExtraBeforeCompInit = ''
      export ZINIT_HOME=${cfg.zinitHome}/zinit

      source ${pkgs.zinit}/share/zinit/zinit.zsh
      ${optionalString cfg.p10k.enable ''
        zinit ice depth=1
        zinit light romkatv/powerlevel10k
      ''}
      ${optionalString (cfg.plugins != [ ]) ''
        ${concatStrings (map (plugin: ''
          ${optionalString (plugin.ice != [ ]) "zinit ice ${
            concatStringsSep " "
            (mapAttrsToList iceToStr (defaultIces // plugin.ice))
          }"}
          zinit ${
            if (isOMZP plugin.name) then "snippet" else "load"
          } "${plugin.name}"
        '') cfg.plugins)}
      ''}
      ${optionalString cfg.enableSyntaxCompletionsSuggestions ''
        zinit wait lucid for \
          atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
              zdharma-continuum/fast-syntax-highlighting \
          blockf \
              zsh-users/zsh-completions \
          atload"!_zsh_autosuggest_start" \
              zsh-users/zsh-autosuggestions
      ''}
    '';
  };
}

