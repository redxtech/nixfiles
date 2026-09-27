{ den, ... }:

{
  den.aspects.travel = {
    nixos = { lib, ... }: {
      options.travel.enable = lib.mkEnableOption "travel mode";

      config.specialisation.travel.configuration = {
        travel.enable = true;

        services = {
          alloy.enable = lib.mkForce false;
          cockpit.enable = lib.mkForce false;
          traefik.enable = lib.mkForce false;
        };

        programs.kdeconnect.enable = lib.mkForce false;

        # the inherited secret remains declared after disabling traefik
        sops.secrets.cloudflare_traefik_token.owner = lib.mkForce "root";

        virtualisation = {
          docker.enableOnBoot = lib.mkForce false;
          libvirtd.enable = lib.mkForce false;

          oci-containers.containers = {
            portainer.autoStart = lib.mkForce false;
            portainer-agent.autoStart = lib.mkForce false;
          };
        };
      };
    };

    homeManager =
      { osConfig, lib, ... }:
      lib.mkIf osConfig.travel.enable {
        services = {
          flatpak.update.auto.enable = lib.mkForce false;
          kdeconnect.enable = lib.mkForce false;
          spotifyd.enable = lib.mkForce false;
          voxtype.enable = lib.mkForce false;
        };

        workstation.autostart = {
          networkMounts = false;
          spotify = false;
          thunderbird = false;
        };
      };
  };
}
