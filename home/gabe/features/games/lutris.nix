{ pkgs, lib, ... }: {
  home.packages = [
    (pkgs.lutris.override { extraPkgs = p: [ p.wine ]; })
  ];
}
