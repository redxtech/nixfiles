{
  # TODO: add binfmt support

  den.aspects.compat.nixos = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.wineWow64Packages.full
    ];
  };
}
