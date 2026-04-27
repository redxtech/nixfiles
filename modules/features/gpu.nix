{ inputs, self, ... }:

{
  den.aspects.gpu = {
    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        cfg = config.gpu;
      in
      {
        options.gpu = {
          amd = lib.mkEnableOption "AMD GPU support";

          nvidia = {
            enable = lib.mkEnableOption "NVIDIA GPU support";
            prime = lib.mkEnableOption "NVIDIA Prime support";
            turingOrNewer = lib.mkEnableOption "NVIDIA Turing or newer support";
          };
        };

        config = lib.mkIf (cfg.amd || cfg.nvidia.enable) {
          # ensure only one of amd or nvidia is enabled
          assertions = [
            {
              assertion = !(cfg.amd && cfg.nvidia.enable);
              message = "Only one of AMD or NVIDIA can be enabled.";
            }
            {
              assertion = !cfg.nvidia.enable;
              message = "NVIDIA module hasn't been tested yet, test before committing to it";
            }
          ];

          environment.systemPackages = with pkgs; [
            amdgpu_top # gpu monitor
            clinfo # OpenCL info tool
          ];

          services.xserver.videoDrivers =
            (lib.optional cfg.amd "amdgpu") ++ (lib.optional cfg.nvidia.enable "nvidia");

          hardware.graphics.extraPackages = lib.optionals cfg.amd [ pkgs.rocmPackages.clr.icd ];

          # from https://nixos.wiki/wiki/Nvidia
          hardware.nvidia = lib.mkIf cfg.nvidia.enable {
            modesetting.enable = true;
            powerManagement.enable = false;
            powerManagement.finegrained = cfg.nvidia.turingOrNewer;
            # open = cfg.nvidia.turingOrNewer; # enable when out of "alpha"
            nvidiaSettings = true;

            prime = lib.mkIf cfg.nvidia.prime {
              # TODO: get the actual values
              # intelBusId = "PCI:0:2:0";
              # nvidiaBusId = "PCI:14:0:0";

              offload = {
                enable = true;
                enableOffloadCmd = true;
              };
            };
          };
        };
      };
  };
}
