{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zsh.zinit;

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
        apply = mapAttrsToList (name: value:
          if "${name}'${value}'" == "wait'0'" then
            "wait"
          else if "${name}'${value}'" == "lucid'true'" then
            "lucid"
          else
            "${name}'${value}'");
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
          ${optionalString (plugin.ice != [ ])
          "zinit ice ${concatStringsSep " " plugin.ice}"}
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

