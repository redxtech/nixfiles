{ config, lib, stable, ... }:

let
  inherit (lib) mkIf;
  cfg = config.desktop.ai;
in {
  options.desktop.ai = let inherit (lib) mkEnableOption;
  in {
    enable = mkEnableOption "Enable gaming-related settings.";

    web-ui = mkEnableOption "Enable the web UI for Ollama.";
  };

  config = mkIf (cfg.enable) {
    services = {
      ollama = {
        enable = true;

        # use the stable nixpkgs version of ollama to avoid rebuilding
        package = if config.base.gpu.amd then
          stable.ollama-rocm
        else if config.base.gpu.nvidia.enable then
          stable.ollama-cuda
        else
          stable.ollama-cpu;

        environmentVariables = {
          OLLAMA_ORIGINS =
            let origins = [ "app://obsidian.md*" "http://bastion:6060" ];
            in (lib.concatStringsSep "," origins);
        };
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
  };
}

