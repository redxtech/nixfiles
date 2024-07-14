{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf;
  cfg = config.base;
in {
  options.base = let inherit (lib) mkOption;
  in with lib.types; {
    containerBackend = mkOption {
      type = enum [ "docker" "podman" ];
      default = "docker";
      description = "The container backend to use.";
    };
  };

  config = let
    inherit (lib) mkDefault;
    dockerEnabled = cfg.containerBackend == "docker";
  in mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      virtiofsd

      wl-clipboard # for waydroid
    ];

    virtualisation = {
      # enable libvirtd
      libvirtd = {
        enable = true;
        qemu.ovmf.enable = true;
        qemu.ovmf.packages = [ pkgs.OVMFFull.fd ];
        qemu.swtpm.enable = true;
        onBoot = "ignore";
        qemu.verbatimConfig = ''
          user = "${cfg.primaryUser}"
        '';
      };

      # allow usb passthrough
      spiceUSBRedirection.enable = true;

      # waydroid.enable = true;
      # lxd.enable = true;

      # docker config
      docker.enable = dockerEnabled;

      # podman config
      podman = {
        enable = true;
        dockerCompat = !dockerEnabled;
        dockerSocket.enable = !dockerEnabled;
        defaultNetwork.settings.dns_enabled = true;
      };

      # use docker for oci containers
      oci-containers.backend = "docker";
    };

    # enable virt-manager
    programs.virt-manager.enable = true;

    # dconf, needed for virt-manager
    programs.dconf.enable = true;

    # this is required by podman to run containers in rootless mode.
    security.unprivilegedUsernsClone =
      mkDefault config.virtualisation.containers.enable;

  };
}
