{ pkgs, lib, config, stable, ... }:

let
  inherit (lib) mkIf mkEnableOption optional optionals;
  cfg = config.base.gpu;
in {
  options.base.gpu = {
    enable = mkEnableOption "GPU support";

    amd = mkEnableOption "AMD GPU support";

    nvidia = {
      enable = mkEnableOption "NVIDIA GPU support";
      prime = mkEnableOption "NVIDIA PRIME support";
      turingOrNewer = mkEnableOption "Turing or newer GPU";
    };
  };

  config = mkIf cfg.enable {
    # ensure only one of amd or nvidia is enabled
    assertions = [
      {
        assertion = !(cfg.amd && cfg.nvidia.enable);
        message = "Only one of AMD or NVIDIA can be enabled.";
      }
      {
        assertion = !cfg.nvidia.enable;
        message =
          "NVIDIA module hasn't been tested yet, test before committing to it";
      }
    ];

    # set the video driver
    boot.initrd.kernelModules = (optional cfg.amd "amdgpu")
      ++ (optional cfg.nvidia.enable "nvidia");
    services.xserver.videoDrivers = (optional cfg.amd "amdgpu")
      ++ (optional cfg.nvidia.enable "nvidia");

    hardware.opengl = with pkgs; {
      enable = true;

      driSupport = true;
      driSupport32Bit = true;

      extraPackages = optionals cfg.amd [
        # ROCm OpenCL ICD
        rocmPackages.clr.icd
        rocm-opencl-icd

        # AMDVLK
        amdvlk
      ];

      extraPackages32 = optionals cfg.amd [ driversi686Linux.amdvlk ];
    };

    # from https://nixos.wiki/wiki/Nvidia
    hardware.nvidia = mkIf cfg.nvidia.enable {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = cfg.nvidia.turingOrNewer;
      # open = cfg.nvidia.turingOrNewer; # enable when out of "alpha"
      nvidiaSettings = true;

      prime = mkIf cfg.nvidia.prime {
        # TODO: get the actual values
        # intelBusId = "PCI:0:2:0";
        # nvidiaBusId = "PCI:14:0:0";

        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
    };

    environment.systemPackages = with pkgs;
      [
        clinfo # OpenCL info tool
      ];
  };
}
