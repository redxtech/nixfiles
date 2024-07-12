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
        nh
        nix
        sops
        ssh-to-age
        yadm
        inputs'.deploy-rs.packages.deploy-rs

        # use the neovim installed with home-manager to ensure binaries are available
        self.nixosConfigurations.bastion.config.home-manager.users.gabe.programs.neovim.finalPackage
      ];

      env.NIX_CONFIG =
        "extra-experimental-features = nix-command flakes repl-flake";
    };
  };
}
