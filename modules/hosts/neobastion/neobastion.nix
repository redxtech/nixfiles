{ den, ... }:

{
  den.hosts.x86_64-linux.neobastion = {
    users.gabe = { };

    settings = {
      base.hasDisplay = true;

      monitors = {
        enable = true;
        monitors = [ ];
      };

      audio.devices = [ ];
    };
  };

  den.aspects.neobastion = {
    includes = [
      den.aspects.workstation
      den.aspects.gpu

      # until no longer on a VM
      den.aspects.vm
    ];

    nixos =
      { pkgs, ... }:
      {
        # fix home-manager not working on temp VMs
        # https://github.com/nix-community/home-manager/issues/6364#issuecomment-2965010115
        home-manager.useUserPackages = true;
      };
  };
}
