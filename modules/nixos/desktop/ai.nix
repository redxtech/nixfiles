{ pkgs, lib, config, ... }:

let
  inherit (lib) mkIf;
  cfg = config.desktop.ai;
in {
  options.desktop.ai = let
    inherit (lib) mkEnableOption;
    mkEnabledOption = description:
      lib.mkOption {
        inherit description;
        type = lib.types.bool;
        default = true;
      };
  in {
    enable = mkEnableOption "Enable gaming-related settings.";

    web-ui = mkEnableOption "Enable the web UI for Ollama.";
    lmstudio = mkEnabledOption "Enable LM Studio.";

    amd = mkEnableOption "Enable AMD ROCM support.";
    nvidia = mkEnableOption "Enable NVIDIA CUDA support.";
  };

  config = mkIf (cfg.enable) {
    # ensure only one of amd or nvidia is enabled
    assertions = [{
      assertion = !(cfg.amd && cfg.nvidia);
      message = "Only one of AMD or NVIDIA can be enabled.";
    }];

    services = {
      ollama = {
        enable = true;

        environmentVariables = {
          OLLAMA_ORIGINS =
            let origins = [ "app://obsidian.md*" "http://bastion:6060" ];
            in (lib.concatStringsSep "," origins);
        };

        acceleration =
          if cfg.amd then "rocm" else if cfg.nvidia then "cuda" else null;
      };

      nextjs-ollama-llm-ui = mkIf cfg.web-ui {
        enable = true;
        port = 6060;
        hostname = "0.0.0.0";
      };
    };

    # override the service to use the correct binary, until https://github.com/NixOS/nixpkgs/pull/319456 is merged
    systemd.services.nextjs-ollama-llm-ui.serviceConfig.ExecStart =
      lib.mkForce "${lib.getExe config.services.nextjs-ollama-llm-ui.package}";

    environment.systemPackages = with pkgs;
      lib.optionals cfg.lmstudio [ lmstudio ];
  };
}

