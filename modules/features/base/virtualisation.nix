{
  den.aspects.virtualisation = {
    nixos =
      { host, pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          virt-manager
          virt-viewer
          virtiofsd
        ];

        virtualisation = {
          libvirtd = {
            enable = true;
            qemu.swtpm.enable = true;
            onBoot = "ignore";
            qemu.verbatimConfig = ''
              user = "${host.settings.base.primaryUser}"
            '';
          };

          # allow usb passthrough
          spiceUSBRedirection.enable = true;
        };

        # for virt-manager
        programs.virt-manager.enable = true;
        programs.dconf.enable = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.virt-manager ];

        # virt-manager autoconnect
        dconf.settings."org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };

    provides.containers.nixos = { host, pkgs, ... }: {
      virtualisation = {
        containers.enable = true;
        docker.enable = true;
        oci-containers.backend = "docker";
      };

      hardware.nvidia-container-toolkit.enable = host.settings.gpu.nvidia.enable;
    };

    # TODO: flesh out, currently unused
    provides.containers-podman.nixos = { config, ... }: {
      # this is required by podman to run containers in rootless mode.
      security.unprivilegedUsernsClone = config.virtualisation.containers.enable;
    };

    provides.waydroid.nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ wl-clipboard ];
        virtualisation.waydroid.enable = true;
      };
  };
}
