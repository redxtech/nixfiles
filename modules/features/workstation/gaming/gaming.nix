{ den, ... }:

{
  den.aspects.gaming = {
    includes = [
      den.aspects.minecraft
    ];

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          eden # switch emulator
        ];
      };
  };
}
