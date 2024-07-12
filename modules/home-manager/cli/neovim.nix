{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
    };

    programs.neovim = {
      enable = true;

      package = pkgs.neovim-nightly;

      withNodeJs = true;
      withPython3 = true;
      withRuby = true;

      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      extraLuaConfig = ''
        -- bootstrap lazy.nvim
        require('config.lazy')
      '';

      neo-lsp = {
        enable = lib.mkDefault true;

        web.deno = true;
        yaml = { kubernetes = true; };
        terraform.enable = true;
      };
    };
  };
}
