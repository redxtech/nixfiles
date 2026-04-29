{ inputs, ... }:

{
  # provide additional options to any systems running build-vm
  # TODO: ignore facter.reportPath in VMs
  den.aspects.vm.nixos.virtualisation.vmVariant.virtualisation = {
    diskSize = 512 * 40;
    memorySize = 1024 * 6;
    cores = 4;

    qemu.options = [
      # display gl enabled
      "-device virtio-vga-gl"
      "-display sdl,gl=on"

      # pipewire audio passthrough
      "-audiodev pipewire,id=audio0"
      "-device ich9-intel-hda"
      "-device hda-duplex,audiodev=audio0"
    ];
  };

  # enables `nix run .#vm`. it is very useful to have a VM
  # you can edit your config and launch the VM to test stuff
  # instead of having to reboot each time.
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.vm = pkgs.writeShellApplication {
        name = "vm";
        text =
          let
            machine = "voyager";
            host = inputs.self.nixosConfigurations.${machine}.config;
          in
          ''
            ${host.system.build.vm}/bin/run-${host.networking.hostName}-vm "$@"
          '';
      };
    };
}
