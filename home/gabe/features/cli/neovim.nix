{ config, pkgs, lib, ... }:

{
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
      -- bootstrap lazy.nvim, lazyvim and my plugins
      require('config.lazy')
    '';

    extraPackages = with pkgs; [
      cargo
      gcc
      gnumake
      go
      nixfmt
      shellcheck

      # language servers & mason binaries
      buf-language-server
      clang-tools
      deno
      docker-compose-language-service
      dockerfile-language-server-nodejs
      hadolint
      helm-ls
      lldb
      luajitPackages.jsregexp
      lua-language-server
      nodePackages.bash-language-server
      nodePackages.prettier
      nodePackages.pyright
      nodePackages.typescript-language-server
      nodePackages.vls
      nodePackages.vscode-json-languageserver-bin
      python311Packages.debugpy
      rnix-lsp
      ruff-lsp
      shfmt
      stylua
      tailwindcss-language-server
      yaml-language-server
      vscode-langservers-extracted
    ];

  };
}

