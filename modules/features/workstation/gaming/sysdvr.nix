{
  den.aspects.sysdvr = {
    nixos = { self', ... }: {
      # receive the console's TCP bridge discovery broadcasts.
      networking.firewall.allowedUDPPorts = [ 19999 ];

      # grant the active desktop session access to SysDVR's USB interface.
      services.udev.packages = [ self'.packages.sysdvr ];
    };

    homeManager = { self', ... }: {
      home.packages = [ self'.packages.sysdvr ];
    };
  };
}
