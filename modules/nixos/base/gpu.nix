{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.base;
in {
  options.base.gpu = {
    enable = mkEnableOption "GPU support";

    amd = { enable = mkEnableOption "AMD GPU support"; };
  };

  config = mkIf cfg.gpu.enable {
    hardware.opengl = mkIf cfg.gpu.amd.enable {
      enable = true;
      extraPackages = with pkgs; [
        # ROCm OpenCL ICD
        rocmPackages.clr.icd
        ocl-icd

        # ROCm
        rocm-opencl-icd
        rocm-runtime-ext

        # AMDVLK
        amdvlk
      ];
    };
  };
}
