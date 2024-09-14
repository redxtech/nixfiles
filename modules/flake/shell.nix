{ ... }:

{
  perSystem = { config, self', inputs', pkgs, system, ... }: {
    devShells = {
      default = pkgs.mkShell {
        packages = with pkgs; [
          age
          cachix
          git
          gnupg
          home-manager
          neovim
          nh
          nix
          sops
          ssh-to-age
          yadm
          inputs'.deploy-rs.packages.deploy-rs
          inputs'.fh.packages.fh
        ];

        env.NIX_CONFIG =
          "extra-experimental-features = nix-command flakes repl-flake";

        shellHook = ''
          alias ls="eza --group-directories-first"
          alias la="ls -la"
          alias l="ls -l"
          alias nrs="nh os switch"
          alias tu="nix run github:redxtech/tu"
        '';

        shell = pkgs.mkShell {
          packages = with pkgs; [
            bat
            btop
            cachix
            dua
            eza
            fd
            fish
            fzf
            git
            gnupg
            home-manager
            neovim
            nh
            nix
            ripgrep
            sops
            starship
            ssh-to-age
            tealdeer

            inputs'.deploy-rs.packages.deploy-rs
            inputs'.fh.packages.fh
          ];

          env.NIX_CONFIG =
            "extra-experimental-features = nix-command flakes repl-flake";

          shellHook = ''
            alias ls="eza --group-directories-first"
            alias la="ls -la"
            alias l="ls -l"
            alias nrs="nh os switch"
            alias tu="nix run github:redxtech/tu"
          '';
        };
      };
    };
  };
}
