{ inputs, ... }:

{
  den.aspects.remaps.nixos = { inputs', host, ... }: {
    imports = [ inputs.xremap.nixosModules.default ];

    services.xremap = {
      enable = true;
      withNiri = true;

      serviceMode = "user";
      userName = host.settings.base.primaryUser;

      config.modmap = [
        {
          name = "Global";
          remap = {
            "CapsLock" = "SUPER_L";
          };
        }
      ];
    };
  };

  flake-file.inputs.xremap = {
    url = "github:xremap/nix-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
