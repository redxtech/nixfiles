{ self, ... }:

{
  den.aspects.moshi.homeManager = {
    imports = [ self.homeManagerModules.moshi ];

    services.moshi-hook.enable = true;
  };
}
