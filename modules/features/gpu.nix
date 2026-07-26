{ lib, ... }:

{
  den.aspects.gpu = {
    settings = {
      # TODO: pull from facter report
      amd = lib.mkEnableOption "AMD GPU support";

      nvidia = {
        enable = lib.mkEnableOption "NVIDIA GPU support";
        prime = lib.mkEnableOption "NVIDIA Prime support";
        turingOrNewer = lib.mkEnableOption "NVIDIA Turing or newer support";
      };
    };

    nixos =
      {
        host,
        config,
        pkgs,
        lib,
        ...
      }:
      let
        cfg = host.settings.gpu;
        hasGPU = config.gpu.hasGPU;
      in
      {
        options.gpu.hasGPU = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether the system has a GPU (useful for disabling the module via specialisation)";
        };

        config = lib.mkIf (hasGPU && (cfg.amd || cfg.nvidia.enable)) {
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

          boot.initrd.kernelModules =
            (lib.optional cfg.amd "amdgpu") ++ (lib.optional cfg.nvidia.enable "nvidia");

          # TODO: check if we need this?
          services.xserver.videoDrivers =
            (lib.optional cfg.amd "amdgpu") ++ (lib.optional cfg.nvidia.enable "nvidia");

          hardware.graphics = {
            enable = true;
            enable32Bit = true;
            extraPackages = lib.optionals cfg.amd [ pkgs.rocmPackages.clr.icd ];
          };

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

          nixpkgs.config.rocmSupport = cfg.amd;
          nixpkgs.config.cudaSupport = cfg.nvidia.enable;
          nixpkgs.config.nvidia.acceptLicense = cfg.nvidia.enable;
        };
      };

    # TODO: add more things to this
    provides.has-removable-gpu = {
      nixos = { config, ... }: {
        specialisation.no-gpu.configuration = {
          gpu.hasGPU = false; # disable all effects of gpu aspect

          nixpkgs.config.cudaSupport = false;
          nixpkgs.config.rocmSupport = false;
        };
      };
    };
  };
}
