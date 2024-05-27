{ self, lib, inputs, ... }:

{
  imports = [ inputs.devenv.flakeModule ];

  perSystem = { config, self', inputs', pkgs, system, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        age
        git
        gnupg
        hci
        home-manager
        neovim-nightly
        nh
        nix
        sops
        ssh-to-age
        yadm

        inputs'.deploy-rs.packages.deploy-rs
      ];

      env.NIX_CONFIG =
        "extra-experimental-features = nix-command flakes repl-flake";
    };

    # devenv.shells = {
    #   default = {
    #     packages = with pkgs; [
    #       age
    #       git
    #       gnupg
    #       home-manager
    #       neovim-nightly
    #       nh
    #       nix
    #       sops
    #       ssh-to-age
    #       yadm

    #       inputs'.deploy-rs.packages.deploy-rs
    #     ];

    #     env.NIX_CONFIG =
    #       "extra-experimental-features = nix-command flakes repl-flake";
    #   };
    # };
  };
}
