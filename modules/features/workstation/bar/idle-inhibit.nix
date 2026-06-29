{ inputs, ... }:

{
  den.aspects.idle-inhibit = {
    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.idle-inhibit.homeModules.default ];

        services.wayland-pipewire-idle-inhibit = {
          enable = true;
          systemdTarget = "sway-session.target";
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
