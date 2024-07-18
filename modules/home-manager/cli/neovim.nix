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

    xdg.desktopEntries."neovim" = {
      name = "neovim";
      genericName = "Text Editor";
      comment = "Edit text files";
      icon = "nvim";
      exec =
        "${config.programs.kitty.package}/bin/kitty ${config.programs.neovim.finalPackage}/bin/nvim %F";
      settings.TryExec = "nvim";
      startupNotify = false;
      type = "Application";
      categories = [ "Utility" "TextEditor" ];
      mimeType = [
        "text/english"
        "text/plain"
        "text/x-makefile"
        "text/x-c++hdr"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-csrc"
        "text/x-java"
        "text/x-moc"
        "text/x-pascal"
        "text/x-tcl"
        "text/x-tex"
        "application/x-shellscript"
        "text/x-c"
        "text/x-c++"
      ];
    };
  };
}
