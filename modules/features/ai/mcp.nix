{
  den.aspects.mcp = {
    homeManager =
      { pkgs, lib, ... }:
      {
        programs.mcp = {
          enable = true;

          servers = {
            nixos.command = lib.getExe pkgs.mcp-nixos;
            # context7 = { };
          };
        };
      };
  };
}
