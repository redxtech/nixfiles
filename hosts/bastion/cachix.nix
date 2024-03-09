{ inputs, pkgs, config, ... }:

{
  services.cachix-agent.enable = true;

  sops.secrets.cachix-agent.sopsFile = ./secrets.yaml;
  sops.secrets.cachix-agent.path = "/etc/cachix-agent.token";
}
