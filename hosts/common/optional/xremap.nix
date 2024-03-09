{ pkgs, inputs, ... }:

{
  imports = [ inputs.xremap-flake.nixosModules.default ];

  services.xremap = {
    withX11 = true;
    config.modmap = [{
      name = "Global";
      remap = { "CapsLock" = "SUPER_L"; };
    }];
  };
}
