{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        EDITOR = "tu";
        VISUAL = "tu";
      };

      packages = with pkgs; [ nil ];
    };

    # my custom, self-contained neovim config
    tu = {
      enable = true;
      packageNames = [ "tu" "tu-dev" "tu-profile" ];
    };

    programs.neovim = {
      enable = true;

      # package = pkgs.neovim-nightly;

      withNodeJs = true;
      withPython3 = true;
      withRuby = true;

      extraPackages = with pkgs; [
        nil

        # for nix-reaver
        nurl

        # for fugit2
        libgit2
        gpgme
        lua5_1
        lua51Packages.luarocks
      ];

      extraLuaConfig = ''
        -- required for smart-open.nvim
        vim.g.sqlite_clib_path = "${pkgs.sqlite.out}/lib/libsqlite3.so"

        vim.g.libgit2_path = "${pkgs.libgit2.lib}/lib/libgit2.so" -- for fugit

        -- bootstrap lazy.nvim
        require('config.lazy')
      '';

      extraWrapperArgs = [
        "--prefix"
        "LD_LIBRARY_PATH"
        ":"
        "${lib.makeLibraryPath [ pkgs.libgit2 ]}"
      ];

      neo-lsp = {
        enable = lib.mkDefault true;

        web.deno = true;
        yaml = { kubernetes = true; };
        terraform.enable = true;
      };

      neovide = {
        enable = true;
        settings = {
          frame = "none";
          neovim-bin = "${config.tu.out.packages.tu}/bin/tu";
          font = {
            normal = [ "Iosevka Comfy" "Symbols Nerd Font" ];
            size = 14.0;
          };
        };
      };
    };

    xdg.desktopEntries."neovim" = {
      name = "neovim";
      genericName = "Text Editor";
      comment = "Edit text files";
      icon = "nvim";
      exec =
        "${config.programs.kitty.package}/bin/kitty ${config.tu.out.packages.tu}/bin/tu %F";
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
