{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ virt-manager ];

  virtualisation = {
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

    # allow usb passthrough
    spiceUSBRedirection.enable = true;

    # enable docker
    docker.enable = true;

    #   waydroid.enable = true;
    #   lxd.enable = true;
  };

  # enable virt-manager
  programs.virt-manager.enable = true;

  # dconf, needed for virt-manager
  programs.dconf.enable = true;

}
