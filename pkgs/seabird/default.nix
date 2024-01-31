{ lib, buildGoModule, fetchFromGitHub, wrapGAppsHook, pkg-config, glib, graphene
, gobject-introspection, gdk-pixbuf, pango, gtk4, gtksourceview5, libadwaita
, libxml2, imagemagick }:

buildGoModule rec {
  pname = "seabird";
  version = "0.0.20";

  src = fetchFromGitHub {
    owner = "getseabird";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-HwQi5ZoDs69L2YETGSv0SwC9Ld9aRyCgGIexW7Uo+co=";
  };

  vendorHash = "sha256-y5UWQBl56ZFmcK6pq+/HtCR+EY4uRlV6MJQ99GFyjIs=";

  nativeBuildInputs = [ wrapGAppsHook pkg-config glib.dev libxml2 imagemagick ];
  buildInputs = [
    glib.dev
    graphene
    gobject-introspection
    gdk-pixbuf
    pango
    gtk4
    gtksourceview5
    libadwaita
  ];

  preBuild = ''
    go generate ./...
  '';

  postInstall = ''
    mkdir -p $out/share/applications
    cp $src/dev.skynomads.Seabird.desktop $out/share/applications/

    for i in 16 24 48 64 96 128 256 512; do
      mkdir -p $out/share/icons/hicolor/''${i}x''${i}/apps
      convert -background none -resize ''${i}x''${i} ./icon/seabird.svg $out/share/icons/hicolor/''${i}x''${i}/apps/dev.skynomads.Seabird.png
    done
  '';

  meta = with lib; {
    description = "Native Kubernetes desktop client.";
    homepage = "https://getseabird.github.io/";
    license = licenses.mpl20;
    maintainers = with maintainers; [ redxtech ];
  };
}
