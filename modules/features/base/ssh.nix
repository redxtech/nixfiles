{ inputs, self, ... }:

{
  den.aspects.ssh = {
    nixos.services.openssh.enable = true;
  };
}
