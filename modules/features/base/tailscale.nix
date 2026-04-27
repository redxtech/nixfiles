{
  den.aspects.tailscale.nixos =
    { config, lib, ... }:
    {
      services.tailscale =
        let
          flags = [
            "--advertise-exit-node"
            "--ssh"
          ];
        in
        {
          enable = true;
          authKeyFile = config.sops.secrets.tailscale-init-authkey.path;

          openFirewall = true;
          useRoutingFeatures = lib.mkDefault "both";
          extraUpFlags = flags;
          extraSetFlags = flags;
        };
      # firewall for tailscale
      networking.firewall = {
        checkReversePath = "loose";
        allowedUDPPorts = [ 41641 ]; # Facilitate firewall punching
      };

      sops.secrets.tailscale-init-authkey = { };
    };
}
