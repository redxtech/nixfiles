{ pkgs ? import <nixpkgs> { } }: rec {

  # Packages with an actual source
  beekeeper-studio-ultimate = pkgs.callPackage ./beekeeper-studio-ultimate { };
  # rgbdaemon = pkgs.callPackage ./rgbdaemon { };
  # shellcolord = pkgs.callPackage ./shellcolord { };

  # Personal scripts
  switchup = pkgs.callPackage ./switchup { };
  nix-inspect = pkgs.callPackage ./nix-inspect { };
  minicava = pkgs.callPackage ./minicava { };
  lyrics = pkgs.python3Packages.callPackage ./lyrics { };

  # My slightly customized plymouth theme, just makes the blue outline white
  plymouth-spinner-monochrome =
    pkgs.callPackage ./plymouth-spinner-monochrome { };
}
