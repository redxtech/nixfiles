{ self, inputs, ... }:

{
  imports = [ inputs.devenv.flakeModule ];

  perSystem = { config, self', inputs', pkgs, system, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        age
        fh
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
      ];

      env.NIX_CONFIG =
        "extra-experimental-features = nix-command flakes repl-flake";

      shellHook = ''
        alias nrs="nh os switch"
      '';
    };
  };
}
