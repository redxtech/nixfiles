{ inputs, ... }:

{
  den.aspects.idle-inhibit = {
    homeManager =
      { config, ... }:
      {
        imports = [ inputs.idle-inhibit.homeModules.default ];

        services.wayland-pipewire-idle-inhibit = {
          enable = true;
          systemdTarget = config.wayland.systemd.target;
          settings = {
            node_blacklist = [ { name = "spotify"; } ];
          };
        };
      };
  };

  flake-file.inputs.idle-inhibit = {
    url = "github:rafaelrc7/wayland-pipewire-idle-inhibit";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
