{ pkgs, inputs, ... }:

{
  default = inputs.devenv.lib.mkShell {
    inherit pkgs inputs;
    modules = [
      ({ pkgs, config, ... }: {
        env.NIX_CONFIG =
          "extra-experimental-features = nix-command flakes repl-flake";

        packages = with pkgs; [
          nix
          home-manager
          git

          age
          sops
          gnupg
          ssh-to-age

          transcrypt
          xxd
          openssl
        ];
      })
    ];
  };

  node = inputs.devenv.lib.mkShell {
    inherit pkgs inputs;
    modules = [
      ({ pkgs, config, ... }: {
        # packages = with pkgs; [ nodejs_latest ];

        languages = {
          javascript = {
            enable = true;
            package = pkgs.nodejs_latest;
            corepack.enable = true;
          };
          typescript.enable = true;
        };

        difftastic.enable = true;
      })
    ];
  };

  python = inputs.devenv.lib.mkShell {
    inherit pkgs inputs;
    modules = [
      ({ pkgs, config, ... }: {
        packages = with pkgs; [ black nodePackages.pyright ];

        languages = {
          python = {
            enable = true;
            poetry.enable = true;
            venv.enable = true;
          };
        };

        difftastic.enable = true;
      })
    ];
  };
}
