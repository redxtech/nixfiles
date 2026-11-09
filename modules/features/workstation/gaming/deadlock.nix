{ inputs, ... }:

{
  den.aspects.deadlock = {
    nixos = {
      imports = [ inputs.hyperline-nix.nixosModules.default ];

      programs.hyperline.enable = true;
    };

    homeManager = { self', ... }: {
      home.packages = with self'.packages; [
        deadlock-mod-manager # mod manager for deadlock
        deadlock-plus # deadlock companion app
      ];
    };
  };

  flake-file.inputs.hyperline-nix = {
    url = "github:paralin/hyperline-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
