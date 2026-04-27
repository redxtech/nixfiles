{ inputs, self, ... }:

# TODO: add provider for docker/podman
{
  den.aspects.virtualization =
    let
      primaryUser = "gabe";
    in
    {
      nixos =
        { config, pkgs, ... }:
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
                user = "${primaryUser}"
              '';
            };

            # allow usb passthrough
            spiceUSBRedirection.enable = true;

          };

          # for virt-manager
          programs.virt-manager.enable = true;

          homeManager =
            { pkgs, ... }:
            {
              home.packages = with pkgs; [
                virt-manager
              ];

              # virt-manager autoconnect
              dconf.settings."org/virt-manager/virt-manager/connections" = {
                autoconnect = [ "qemu:///system" ];
                uris = [ "qemu:///system" ];
              };
            };
        };

      provides.waydroid.nixos =
        { pkgs, ... }:
        {
          environment.systemPackages = with pkgs; [ wl-clipboard ];
          virtualisation.waydroid.enable = true;
        };
    };
}
