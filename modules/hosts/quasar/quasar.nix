{ den, inputs, ... }:

{
  den.hosts.x86_64-linux.quasar = {
    users.gabe = { };
    # users.data = { };

    settings = {
      base = {
        dockerDNS = [ "192.168.50.1" ];
        fs.btrfs = true;
        fs.zfs = true;
      };

      network = {
        isHost = true;
        ip = "192.168.50.208";
      };

      tunnel.id = "7f867cbe-8898-4ff6-be4c-8a3ab626b456";

      # gpu.nvidia.enable = true;
    };
  };

  den.aspects.quasar = {
    includes = [
      den.aspects.quasar-fs
      den.aspects.base
      # den.aspects.server
      den.aspects.network
      den.aspects.tunnel
      den.aspects.dns

      den.aspects.gpu
    ];

    nixos = {
      imports = with inputs.nixos-hardware.nixosModules; [
        common-cpu-intel-cpu-only
        common-gpu-nvidia-nonprime
        common-pc-ssd
      ];

      hardware.facter.reportPath = ./facter.json;

      system.stateVersion = "23.11";

      # TODO: should i switch it to 75d9f980 ? (etc/machine-id)
      networking.hostId = "74996f49";

      # fix home-manager not working on temp VMs
      # https://github.com/nix-community/home-manager/issues/6364#issuecomment-2965010115
      home-manager.useUserPackages = true;
      # home-manager.backupFileExtension = "bak";
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [ moonlight-qt ];
      };
  };

  flake-file.inputs.nixos-hardware.url = "github:nixos/nixos-hardware";
}
