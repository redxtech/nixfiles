{ inputs, ... }:

{
  den.aspects.keymasq.nixos =
    { pkgs, ... }:
    {
      imports = [ inputs.keymasq.nixosModules.default ];

      services.keymasq = {
        enable = true;
        installPackage = true;
      };
    };

  flake-file.inputs.keymasq.url = "github:nyrda/keymasq";
}
