{ den, inputs, ... }:

{
  den.hosts.x86_64-linux.quasar = {
    users.gabe = { };
    # users.data = { };

    settings = {
      base = {
        dockerDNS = [ "192.168.1.1" ];
        fs.btrfs = true;
        fs.zfs = true;
      };

      # gpu.nvidia.enable = true;
    };
  };

  den.aspects.quasar = {
    includes = [
      # den.aspects.quasar-fs
      den.aspects.base
      # den.aspects.server
      den.aspects.gpu

      # until no longer on a VM
      # den.aspects.vm
    ];

    nixos = {
      imports = with inputs.nixos-hardware.nixosModules; [
        common-cpu-intel-cpu-only
        common-gpu-nvidia-nonprime
        common-pc-ssd
      ];

      # TODO: re-enable when not testing in a VM
      # hardware.facter.reportPath = ./facter.json;

      system.stateVersion = "23.11";

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
