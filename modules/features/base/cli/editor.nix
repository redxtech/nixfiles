{ inputs, ... }:

{
  den.aspects.editor = {
    homeManager =
      { config, pkgs, ... }:
      {
        imports = [ inputs.tu.homeManagerModules.default ];

        home = {
          sessionVariables.VISUAL = "tu";
          packages = with pkgs; [ nil ];
        };

        # my custom, self-contained neovim config
        wrappers.tu.enable = true;

        programs.neovim = {
          enable = true;
          withNodeJs = true;
          withPython3 = true;
          withRuby = true;
        };

        programs.zed-editor = {
          enable = true;

          installRemoteServer = true;
          enableMcpIntegration = true;

          extensions = [
            "dockerfile"
            "docker-compose"
            "dracula"
            "env"
            "html"
            "lua"
            "nix"
            "toml"
            "vue"
          ];

          # extraPackages = with pkgs; [ ];
        };
      };

    # only include this if the host imports the sub-aspect
    provides.for-workstation.homeManager =
      { config, lib, ... }:
      {
        programs.neovide = {
          enable = true;
          settings = {
            frame = "none";
            neovim-bin = lib.getExe config.wrappers.tu.wrapper;
          };
        };

        xdg.desktopEntries."neovim" = {
          name = "neovim (tu)";
          genericName = "Text Editor";
          comment = "Edit text files - custom config";
          icon = "nvim";
          exec = "${lib.getExe config.programs.kitty.package} ${lib.getExe config.wrappers.tu.wrapper} %F";
          settings.TryExec = lib.getExe config.wrappers.tu.wrapper;
          startupNotify = false;
          type = "Application";
          categories = [
            "Utility"
            "TextEditor"
          ];
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
  };

  flake-file.inputs.tu = {
    url = "github:redxtech/tu";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
