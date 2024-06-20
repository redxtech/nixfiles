{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.programs.neovim.neo-lsp;
in {
  options.programs.neovim.neo-lsp = let
    inherit (lib) mkEnableOption mkOption types;

    mkOnOff = description: default:
      mkOption {
        inherit default description;
        type = types.bool;
        example = !default;
      };

    mkLsp = lang: mkOnOff ("Install " + lang + " binaries") true;
    mkDisable = lang: mkOnOff ("Install " + lang + " binaries") false;
    mkLang = lang: { enable = mkLsp lang; };
    mkLangDisable = lang: { enable = mkDisable lang; };
  in {
    enable = mkEnableOption "Enable neovim LSP installation";

    web = {
      enable = mkOnOff "Enable web LSPs" true;

      typescript = mkLsp "typescript";
      biome = mkLsp "biome";
      prettier = mkLsp "prettier";
      eslint = mkLsp "eslint";
      vue = mkLsp "vue";
      svelte = mkLsp "svelte";
      # react = mkLsp "react";
      tailwind = mkLsp "tailwind";

      deno = mkDisable "deno";
    };

    lua = mkLang "lua";
    nix = mkLang "nix";
    rust = mkLang "rust";
    python = mkLang "python";
    shell = mkLang "shell";
    go = mkLang "go";
    cpp = mkLang "cpp";

    php = mkLangDisable "php";
    java = mkLangDisable "java";
    dotnet = mkLangDisable "dotnet";
    zig = mkLangDisable "zig";
    terraform = mkLangDisable "terraform";
    haskell = mkLangDisable "haskell";

    yaml = {
      enable = mkLsp "yaml";

      docker = mkLsp "docker";
      kubernetes = mkDisable "kubernetes";
      ansible = mkDisable "ansible";
    };
  };

  config = mkIf cfg.enable {
    programs.neovim = {
      extraLuaPackages = rocks: [ rocks.jsregexp ];

      extraPackages = let
        inherit (lib) optional optionals;

        default = with pkgs; [
          tree-sitter
          git
          curl
          gnutar
          gnumake
          trashy
          buf-language-server
          wl-clipboard
          xclip
        ];

        web = with pkgs;
          ([
            vscode-langservers-extracted
            nodePackages.vscode-json-languageserver-bin
          ] ++ (optional cfg.web.typescript
            nodePackages.typescript-language-server)
            ++ (optional cfg.web.biome biome)
            ++ (optionals cfg.web.prettier [ prettierd nodePackages.prettier ])
            ++ (optional cfg.web.eslint nodePackages.eslint)
            ++ (optional cfg.web.vue nodePackages.volar)
            ++ (optional cfg.web.svelte nodePackages.svelte-language-server)
            ++ (optional cfg.web.tailwind tailwindcss-language-server)
            ++ (optional cfg.web.deno deno));

        lua = with pkgs; [ lua-language-server stylua ];
        nix = with pkgs; [ nil nixfmt-classic ];
        rust = with pkgs; [
          cargo # switch to use fenix ?
          rustfmt
          rust-analyzer # use nightly
        ];
        python = with pkgs; [ black ruff-lsp python3Packages.debugpy pyright ];
        shell = with pkgs; [
          shellcheck
          shfmt
          nodePackages.bash-language-server
          # fish-lsp
        ];
        go = with pkgs; [ pkgs.go gopls ];
        cpp = with pkgs; [ clang-tools gcc lldb ];
        tf = with pkgs; [ terraform terraform-ls tflint ];

        yaml = with pkgs;
          ([ yaml-language-server ]
            ++ (optional cfg.yaml.ansible ansible-language-server)
            ++ (optionals cfg.yaml.kubernetes [ kubectl helm-ls ])
            ++ (optionals cfg.yaml.docker [
              dockerfile-language-server-nodejs
              docker-compose-language-service
              hadolint
            ]));

        installed = default ++ (optionals cfg.web.enable web)
          ++ (optionals cfg.lua.enable lua) ++ (optionals cfg.nix.enable nix)
          ++ (optionals cfg.rust.enable rust)
          ++ (optionals cfg.python.enable python)
          ++ (optionals cfg.shell.enable shell) ++ (optionals cfg.go.enable go)
          ++ (optionals cfg.terraform.enable tf)
          ++ (optionals cfg.cpp.enable cpp) ++ (optionals cfg.yaml.enable yaml);
      in installed;
    };
  };
}
