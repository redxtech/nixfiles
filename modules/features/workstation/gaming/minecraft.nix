{
  den.aspects.minecraft = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          # best launcher & mod manager
          prismlauncher

          # java version needed for latest minecraft
          openjdk25
        ];
      };
  };
}
