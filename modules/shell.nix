{ inputs, self, ... }:

{
  perSystem =
    { pkgs, inputs', ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          neovim
          nix

          # secrets
          age
          age-plugin-yubikey
          ssh-to-age
          sops

          # remote deploy
          inputs'.deploy-rs.packages.deploy-rs
        ];

        env.NIX_CONFIG = "extra-experimental-features = nix-command flakes";

        shellHook = ''
          alias ls="eza --group-directories-first"
          alias la="ls -la"
          alias l="ls -l"
          alias nrs="nh os switch"
          alias tu="nix run github:redxtech/tu"
        '';
      };
    };
}
