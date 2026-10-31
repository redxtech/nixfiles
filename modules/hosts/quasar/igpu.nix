{
  den.aspects.quasar-igpu.nixos =
    { pkgs, ... }:
    {
      boot.kernelModules = [ "i915" ];

      hardware.graphics = {
        enable = true;
        extraPackages = [ pkgs.intel-media-driver ];
      };

      systemd.services.plex.serviceConfig.SupplementaryGroups = [
        "render"
        "video"
      ];

      virtualisation.oci-containers.containers.jellyfin.devices = [
        "/dev/dri:/dev/dri"
      ];
    };
}
