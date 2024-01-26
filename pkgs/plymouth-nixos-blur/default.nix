{ stdenv, fetchFromGitea, ... }:

stdenv.mkDerivation rec {
  pname = "plymouth-nixos-blur";
  version = "2022-07-08";

  src = fetchFromGitea {
    domain = "git.gurkan.in";
    owner = "gurkan";
    repo = "nixos-blur-plymouth";
    rev = "ea75b51a1f04aa914647a2929eab6bbe595bcfc0";
    hash = "sha256-BSmh+Gy3yJMA4RoJ0uaQ/WsYBs+Txr6K3cAQjf+yM5Y=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/plymouth/themes/
    cp -r $src/nixos-blur $out/share/plymouth/themes/nixos-blur

    substituteInPlace $out/share/plymouth/themes/nixos-blur/*.plymouth \
      --replace 'etc/plymouth/themes/nixos-blur' "$out/share/plymouth/themes/nixos-blur"

    runHook postInstall
  '';
}
