{ pkgs, lib, config, stable, ... }:

let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.base.gpu;
in {
  options.base.gpu = {
    enable = mkEnableOption "GPU support";

    amd = mkEnableOption "AMD GPU support";
    nvidia = mkEnableOption "NVIDIA GPU support";
  };

  config = mkIf cfg.enable {
    # ensure only one of amd or nvidia is enabled
    assertions = [{
      assertion = !(cfg.amd && cfg.nvidia);
      message = "Only one of AMD or NVIDIA can be enabled.";
    }];

    hardware.opengl = mkIf cfg.amd {
      enable = true;
      extraPackages = with pkgs; [
        # ROCm OpenCL ICD
        rocmPackages.clr.icd
        rocm-opencl-icd

        # AMDVLK
        amdvlk
      ];
    };
  };
}
