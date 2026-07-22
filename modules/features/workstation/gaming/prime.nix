{ self, lib, ... }:

# reference:
# https://wiki.nixos.org/wiki/NVIDIA
# https://wiki.archlinux.org/title/PRIME

{
  # NOTE:needs to be enabled per-host
  den.aspects.prime = {
    nixos =
      {
        host,
        config,
        pkgs,
        ...
      }:
      let
        enableAMD = host.settings.gpu.amd;
        enableNvidia = host.settings.gpu.nvidia.enable;

        inherit (config.hardware.facter) report;
        inherit (self.lib.gpu.device-classes) devicesInClass; # NOTE: very limited, only has data for my laptop

        mkPrimePath = bus_id: "pci-${lib.replaceStrings [ ":" "." ] [ "_" "_" ] bus_id}";
        integrated = mkPrimePath (lib.head (devicesInClass "integrated" report)).sysfs_bus_id;
        dedicated = mkPrimePath (lib.head (devicesInClass "discrete" report)).sysfs_bus_id;
      in
      {
        assertions = [
          {
            assertion = integrated != null;
            message = "integrated gpu path couldn't be detected from facter report";
          }
          {
            assertion = dedicated != null;
            message = "dedicated gpu path couldn't be detected from facter report";
          }
        ];

        # hardware.bumblebee.enable = true;
        hardware.nvidia.prime.offload.enable = enableNvidia;

        programs.steam.gamescopeSession.env.DRI_PRIME = dedicated;

        # requires `hardware.nvidia.prime.offload.enable`.
        programs.gamescope.env = lib.mkIf enableNvidia {
          __NV_PRIME_RENDER_OFFLOAD = "1";
          __VK_LAYER_NV_optimus = "NVIDIA_only";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        };

        programs.gamemode.settings.gpu.amd_performance_level = lib.mkIf enableAMD "high";

        environment.sessionVariables = lib.mkIf enableAMD {
          DRI_PRIME = integrated;
          DRI_PRIME_INTERNAL = integrated;
          DRI_PRIME_DEDICATED = dedicated;
        };
      };
  };
}
