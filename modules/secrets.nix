{ inputs, self, ... }:

{
  den.aspects.secrets = {
    nixos =
      { config, pkgs, ... }:
      {
        imports = [ inputs.sops-nix.nixosModules.sops ];

        environment.systemPackages = with pkgs; [ age-plugin-yubikey ];

        sops =
          let
            isEd25519 = k: k.type == "ed25519";
            getKeyPath = k: k.path;
            keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
          in
          {
            defaultSopsFile = ../secrets/hosts/common/secrets.yaml;
            age.sshKeyPaths = map getKeyPath keys;
          };
      };

    homeManager =
      { lib, ... }:
      {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];

        sops = {
          defaultSopsFile = ../secrets/users/gabe/secrets.yaml;
          age.sshKeyPaths = lib.mkDefault [ "/home/gabe/.ssh/id_ed25519" ];
        };
      };
  };

  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
