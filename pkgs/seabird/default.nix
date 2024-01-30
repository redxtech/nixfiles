{ lib, buildGoModule, fetchFromGitHub, wrapGAppsHook, pkg-config, glib, graphene
, gobject-introspection, gdk-pixbuf, pango, gtk4, gtksourceview5, libadwaita
, libxml2 }:

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

  nativeBuildInputs = [ wrapGAppsHook pkg-config glib.dev libxml2 ];
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

  meta = with lib; {
    description = "Native Kubernetes desktop client.";
    homepage = "https://getseabird.github.io/";
    license = licenses.mpl20;
    maintainers = with maintainers; [ redxtech ];
  };
}
