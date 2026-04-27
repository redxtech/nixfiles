{ inputs, den, ... }:

{
  den.hosts.x86_64-linux.quasar = {
    users.gabe = { };
    # users.data = { };
  };

  den.aspects.quasar = {
    includes = [
      # den.aspects.quasar-fs
      den.aspects.base
      # den.aspects.server
      # den.aspects.gpu

      # until no longer on a VM
      # den.aspects.vm
    ];

    nixos = {
      # imports = [ inputs.nixos-hardware.nixosModules.framework-16-7040-amd ];

      # TODO: re-enable when not testing in a VM
      # hardware.facter.reportPath = ./facter.json;

      system.stateVersion = "23.11";

      gpu.nvidia.enable = true;

      # fix home-manager not working on temp VMs
      # https://github.com/nix-community/home-manager/issues/6364#issuecomment-2965010115
      # TODO: remove this when not testing in a VM
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "bak";
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ moonlight-qt ];
      };
  };

  flake-file.inputs = {
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
  };
}
