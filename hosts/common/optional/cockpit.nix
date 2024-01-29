{ config, lib, pkgs, ... }:

{
  services.cockpit = {
    enable = true;

    package = pkgs.cockpit.overrideAttrs (old: {
      postBuild = ''
        ${old.postBuild}

        rm -rf \
          dist/packagekit \
          dist/selinux
      '';
    });

    port = lib.mkDefault 9090;
    openFirewall = true;

    settings = { WebService = { AllowUnencrypted = true; }; };
  };

  environment.systemPackages = with pkgs; [
    cockpit-benchmark
    cockpit-docker
    cockpit-file-sharing
    cockpit-machines
    cockpit-tailscale
    libvirt-dbus
    virt-manager
  ];
}
