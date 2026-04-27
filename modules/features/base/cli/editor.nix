{ inputs, self, ... }:

{
  den.aspects.editor = {
    homeManager =
      { config, pkgs, ... }:
      {
        imports = [ inputs.tu.homeModules.default ];

        home = {
          sessionVariables = {
            EDITOR = "tu";
            VISUAL = "tu";
            # PAGER = "tu +Man!";
          };

          packages = with pkgs; [ nil ];
        };

        # my custom, self-contained neovim config
        # TODO: move to nix-wrapper-modules
        tu = {
          enable = true;
          packageNames = [
            "tu"
            "tu-dev"
            "tu-profile"
          ];
        };

        programs.neovim = {
          enable = true;
          withNodeJs = true;
          withPython3 = true;
          withRuby = true;
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
            neovim-bin = lib.getExe config.tu.out.packages.tu;
          };
        };

        xdg.desktopEntries."neovim" = {
          name = "neovim (tu)";
          genericName = "Text Editor";
          comment = "Edit text files - custom config";
          icon = "nvim";
          exec = "${lib.getExe config.programs.kitty.package} ${lib.getExe config.tu.out.packages.tu} %F";
          settings.TryExec = lib.getExe config.tu.out.packages.tu;
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
