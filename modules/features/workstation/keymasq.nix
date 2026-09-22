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

  den.aspects.keymasq.homeManager =
    { config, ... }:
    let
      configRoot = "${config.home.homeDirectory}/Code/nixfiles/modules/features/workstation/keymasq";
      link = path: config.lib.file.mkOutOfStoreSymlink "${configRoot}/${path}";
    in
    {
      xdg.configFile = {
        "keymasq/profiles".source = link "shared/profiles";
        "keymasq/superkeys".source = link "shared/superkeys";
        "keymasq/analog_controls".source = link "shared/analog_controls";
        "keymasq/motion_controls".source = link "shared/motion_controls";
        "keymasq/hardware".source = link "shared/hardware";
      };
    };

  flake-file.inputs.keymasq.url = "github:nyrda/keymasq";
}
