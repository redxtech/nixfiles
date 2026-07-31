{
  den.aspects.virtualisation = {
    nixos =
      { host, pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          virt-manager
          virt-viewer
          virtiofsd
        ];

        virtualisation = {
          libvirtd = {
            enable = true;
            qemu.swtpm.enable = true;
            onBoot = "ignore";
            qemu.verbatimConfig = ''
              user = "${host.settings.base.primaryUser}"
            '';
          };

          # allow usb passthrough
          spiceUSBRedirection.enable = true;
        };

        # for virt-manager
        programs.virt-manager.enable = true;
        programs.dconf.enable = true;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.virt-manager ];

        # virt-manager autoconnect
        dconf.settings."org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };

    provides.containers.nixos =
      {
        config,
        host,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.virtualisation.oci-containers;
        networkNames = lib.attrNames cfg.networks;
        attachedContainerNames = lib.unique (lib.concatLists (lib.attrValues cfg.networks));
        unitName = network: "docker-network-${network}.service";
        attachedNetworks =
          containerName: lib.filter (network: lib.elem containerName cfg.networks.${network}) networkNames;
      in
      {
        options.virtualisation.oci-containers.networks = lib.mkOption {
          type = lib.types.attrsOf (lib.types.listOf lib.types.str);
          default = { };
          example.booklore = [
            "booklore"
            "booklore-mariadb"
          ];
          description = "Docker bridge networks mapped to the OCI containers attached to them.";
        };

        config = {
          assertions = [
            {
              assertion = lib.all (
                network: builtins.match "[a-zA-Z0-9][a-zA-Z0-9_.-]*" network != null
              ) networkNames;
              message = "Managed Docker network names contain unsupported characters.";
            }
            {
              assertion = lib.all (
                name: (config.virtualisation.oci-containers.containers.${name}.image or "") != ""
              ) attachedContainerNames;
              message = "Managed Docker networks reference an undefined OCI container.";
            }
          ];

          virtualisation = {
            containers.enable = true;
            docker.enable = true;
            oci-containers = {
              backend = "docker";
              containers = lib.genAttrs attachedContainerNames (name: {
                extraOptions = map (network: "--network=${network}") (attachedNetworks name);
              });
            };
          };

          hardware.nvidia-container-toolkit.enable = host.settings.gpu.nvidia.enable;

          systemd.services =
            (lib.listToAttrs (
              map (network: {
                name = "docker-network-${network}";
                value = {
                  description = "Create the ${network} Docker network";
                  after = [ "docker.service" ];
                  requires = [ "docker.service" ];
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                  };
                  script = ''
                    ${lib.getExe pkgs.docker} network inspect ${lib.escapeShellArg network} >/dev/null 2>&1 \
                      || ${lib.getExe pkgs.docker} network create --driver bridge ${lib.escapeShellArg network}
                  '';
                };
              }) networkNames
            ))
            // lib.mapAttrs' (
              name: _:
              let
                units = map unitName (attachedNetworks name);
              in
              lib.nameValuePair "docker-${name}" (
                lib.mkIf (units != [ ]) {
                  after = units;
                  requires = units;
                }
              )
            ) (lib.genAttrs attachedContainerNames (_: { }));
        };
      };

    # TODO: flesh out, currently unused
    provides.containers-podman.nixos = { config, ... }: {
      # this is required by podman to run containers in rootless mode.
      security.unprivilegedUsernsClone = config.virtualisation.containers.enable;
    };

    provides.waydroid.nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [ wl-clipboard ];
        virtualisation.waydroid.enable = true;
      };
  };
}
