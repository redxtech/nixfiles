{ pkgs, inputs, ... }:

{
  imports = [ inputs.xremap-flake.nixosModules.default ];

  services.xremap = {
    withX11 = true;
    config.modmap = [{
      name = "Global";
      remap = { "CapsLock" = "Hyper"; }; # globally remap CapsLock to Esc
    }];
  };
}
