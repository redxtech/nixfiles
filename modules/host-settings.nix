{ den, ... }:

# pass host settings to nixos and home-manager
{
  den.aspects.host-settings = den.lib.perHost (
    { host }:
    {
      nixos = {
        _module.args.settings = host.settings;
        home-manager.sharedModules = [ { _module.args.host = host; } ];
      };
    }
  );
}
