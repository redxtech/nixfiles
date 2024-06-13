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

        environmentVariables = { OLLAMA_ORIGINS = "app://obsidian.md*"; };

        acceleration =
          if cfg.amd then "rocm" else if cfg.nvidia then "cuda" else null;
      };

      # disabled until i update nixpkgs
      # nextjs-ollama-llm-ui = mkIf cfg.web-ui {
      #   enable = true;
      #   port = 6000;
      # };
    };

    environment.systemPackages = with pkgs;
      lib.optionals cfg.lmstudio [ lmstudio ];
  };
}

