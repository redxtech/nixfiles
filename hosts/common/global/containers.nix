{ config, pkgs, ... }:

let dockerEnabled = true;
in {
  virtualisation = {
    docker = { enable = dockerEnabled; };

    podman = {
      enable = true;
      dockerCompat = !dockerEnabled;
      dockerSocket.enable = !dockerEnabled;
      defaultNetwork.settings.dns_enabled = true;
    };

    oci-containers = { backend = "docker"; };

    # enable libvirtd
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
      qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];
      qemu.swtpm.enable = true;
      onBoot = "ignore";
      qemu.verbatimConfig = ''
        user = "gabe"
      '';
    };
  };
}
