{ den, inputs, ... }:

{
  den.aspects.bar = {
    includes = [
      den.aspects.noctalia-plugins
      den.aspects.idle-inhibit
    ];

    nixos =
      {
        host,
        pkgs,
        lib,
        ...
      }:
      {
        # to make noctalia’s wifi, bluetooth, power-profile, and battery features available
        networking.networkmanager.enable = true;
        hardware.bluetooth.enable = true;
        services.power-profiles-daemon.enable = lib.mkIf host.settings.workstation.isLaptop true;
        services.upower.enable = true;

        # TODO: enable gnome evolution data server for calendar support
      };

    homeManager =
      {
        inputs',
        config,
        host,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ inputs.noctalia.homeModules.default ];

        home.packages =
          with pkgs;
          [
            fastfetch # for system information
          ]
          ++ lib.optionals host.settings.workstation.isLaptop (
            with pkgs;
            [
              ddcutil # brightness controls
            ]
          );

        programs.noctalia = {
          enable = true;

          package = inputs'.noctalia.packages.default;

          systemd.enable = true;

          settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ./noctalia-config.toml)) {
            shell = {
              avatar_path = "${config.home.homeDirectory}/.face";
              screenshot.directory = "${config.xdg.userDirs.pictures}/Screenshots";
            };

            wallpaper =
              let
                wp_dir = "${config.xdg.userDirs.pictures}/Wallpaper";
              in
              {
                directory = wp_dir;
                default.path = "${wp_dir}/new_beginning_4k.png";
                last.path = "${wp_dir}/new_beginning_4k.png";
                monitors.DP-1.path = "${wp_dir}/new_beginning_4k.png";
                monitors.DP-2.path = "${wp_dir}/new_beginning_4k.png";
                monitors.Virtual-1.path = "${wp_dir}/new_beginning_4k.png";
              };

            lockscreen_widgets = builtins.fromTOML (
              builtins.readFile ./lockscreen-widgets/${host.hostName}.toml
            );

            # TODO: set idle.behavior.screen-off.command to niri's power-off-monitors
            # idle.behavior.screen-off.command = "niri msg action power-off-monitors";
          };
        };

        # sops.secrets = {
        #   github-feed = {
        #     sopsFile = ../../../../secrets/users/gabe/noctalia.yaml;
        #     path = config.xdg.configHome + "/noctalia/plugins/github-feed/settings.json";
        #   };
        #   hassio = {
        #     sopsFile = ../../../../secrets/users/gabe/noctalia.yaml;
        #     path = config.xdg.configHome + "/noctalia/plugins/hassio/settings.json";
        #   };
        # };
      };
  };

  # allow exporting noctalia config to a file
  perSystem =
    { pkgs, lib, ... }:
    {
      apps.write-noctalia = {
        type = "app";
        program = pkgs.writeShellApplication {
          name = "write-noctalia";
          runtimeInputs = with pkgs; [
            inputs.noctalia.packages.${stdenv.hostPlatform.system}.default
            yq-go
          ];
          text = ''
            noctalia config export > ~/Code/nixfiles/modules/features/workstation/bar/noctalia-config.toml
            noctalia config export | yq -p toml -o toml '.lockscreen_widgets' > ~/Code/nixfiles/modules/features/workstation/bar/lockscreen-widgets/"$(hostname).toml"
          '';
        };
        meta.description = "Export noctalia config to a file, and export the device-specific lockscreen widgets";
      };
    };

  flake-file.inputs.noctalia.url = "github:noctalia-dev/noctalia/cachix";

  flake-file.nixConfig = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };
}
