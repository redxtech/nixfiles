{ lib, ... }:

{
  den.aspects.tailscale = {
    settings.tailnet = lib.mkOption {
      type = lib.types.str;
      default = "colobus-pirate.ts.net";
      description = "The tailnet to use.";
    };

    settings.advertiseTags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Tailscale tags advertised by this host.";
    };

    nixos =
      {
        config,
        host,
        lib,
        ...
      }:
      {
        services.tailscale =
          let
            setFlags = [
              "--advertise-exit-node"
              "--ssh"
            ];
            upFlags =
              setFlags
              ++ lib.optional (
                host.settings.tailscale.advertiseTags != [ ]
              ) "--advertise-tags=${lib.concatStringsSep "," host.settings.tailscale.advertiseTags}";
          in
          {
            enable = true;
            authKeyFile = config.sops.secrets.tailscale-init-authkey.path;

            openFirewall = true;
            useRoutingFeatures = lib.mkDefault "both";
            extraUpFlags = upFlags;
            # tailscale set does not support changing advertised tags.
            extraSetFlags = setFlags;
          };

        # firewall for tailscale
        networking.firewall = {
          checkReversePath = "loose";
          allowedUDPPorts = [ 41641 ]; # Facilitate firewall punching
        };

        sops.secrets.tailscale-init-authkey.sopsFile = ../../../secrets/hosts/common/secrets.yaml;
      };

    provides.server.nixos =
      { config, pkgs, ... }:
      let
        docktailServiceNames = lib.filter (name: name != null) (
          lib.mapAttrsToList (
            _containerName: container: lib.attrByPath [ "labels" "docktail.service.name" ] null container
          ) config.virtualisation.oci-containers.containers
        );
        # docktail owns labeled OCI services; avoid configuring the same
        # tailscale service through both the native reconciler and docktail.
        services = removeAttrs config.network.finalServices docktailServiceNames;
        servicesFile = pkgs.writeText "tailscale-serve-services.json" (builtins.toJSON services);
        docktailServicesFile = pkgs.writeText "tailscale-serve-docktail-services.json" (
          builtins.toJSON docktailServiceNames
        );
        # TODO: this is a workaround until issue (https://github.com/tailscale/tailscale/issues/18381) is fixed
        reconcileServe = pkgs.writeShellApplication {
          name = "tailscale-serve-reconcile";
          runtimeInputs = [
            config.services.tailscale.package
            pkgs.jq
          ];
          text = ''
            status="$(tailscale serve status --json)"

            while IFS= read -r service; do
              name="''${service#svc:}"
              if jq --exit-status --arg name "$name" 'has($name)' ${servicesFile} >/dev/null \
                || jq --exit-status --arg name "$name" 'index($name) != null' ${docktailServicesFile} >/dev/null; then
                continue
              fi

              tailscale serve clear "$service"
            done < <(jq --raw-output '(.Services // {}) | keys[]' <<< "$status")

            while IFS=$'\t' read -r name port; do
              service="svc:$name"
              target="http://127.0.0.1:$port"

              if jq --exit-status \
                --arg service "$service" \
                --arg target "$target" \
                '(.Services[$service].TCP["443"].HTTPS == true)
                  and ([.Services[$service].Web[]?.Handlers["/"].Proxy?] | index($target) != null)' \
                <<< "$status" >/dev/null; then
                tailscale serve advertise "$service"
                continue
              fi

              if jq --exit-status --arg service "$service" '(.Services // {}) | has($service)' \
                <<< "$status" >/dev/null; then
                tailscale serve clear "$service"
              fi

              tailscale serve \
                --service="$service" \
                --https=443 \
                --bg \
                --yes \
                "$target"
            done < <(jq --raw-output 'to_entries[] | [.key, (.value | tostring)] | @tsv' ${servicesFile})
          '';
        };
      in
      lib.mkIf (services != { }) {
        # set-config currently loses the HTTPS listener when its backend uses
        # HTTP, so reconcile through the protocol-aware CLI instead.
        # https://github.com/tailscale/tailscale/issues/18381
        systemd.services.tailscale-serve = {
          description = "Tailscale Serve Configuration";
          after = [
            "tailscaled.service"
            "tailscaled-autoconnect.service"
            "tailscaled-set.service"
          ];
          wants = [ "tailscaled.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = lib.getExe reconcileServe;
          };
        };
      };
  };
}
