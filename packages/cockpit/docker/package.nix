{
  perSystem =
    { pkgs, lib, ... }:
    {
      # TODO: fix npm build
      packages.cockpit-docker =
        let
          inherit (pkgs)
            buildNpmPackage
            fetchFromGitHub
            sass
            webpack-cli
            ;

          pname = "cockpit-docker";
          version = "0-unstable-2024-03-02";
        in
        buildNpmPackage {
          inherit pname version;

          src = fetchFromGitHub {
            owner = "pk5ls20";
            repo = "cockpit-docker-upstream-mrevjd";
            rev = "a8e2880074efc8fc1225139d87c00566ceb0ce24";
            hash = "sha256-IIsj5GWgJmjBFmvYgY4qAnYQv4iCsJfSWwZNkfiTLS4=";
          };

          npmDepsFetcherVersion = 2;
          npmDepsHash = "sha256-+e3AigbwXWaWNq0iiZmhdbr/T1n6R6Oh/KLRenzd94c=";
          makeCacheWritable = true;

          nativeBuildInputs = [
            webpack-cli
            sass
          ];

          prePatch = ''
            substituteInPlace package.json --replace-fail '"node-sass": "^4.13.1",' ' '
          '';

          buildPhase = ''
            webpack
          '';

          installPhase = ''
            mkdir -p $out/share/cockpit
            cp -r dist/docker $out/share/cockpit/docker
          '';

          NODE_OPTIONS = [ "--openssl-legacy-provider" ];

          meta = with lib; {
            description = "Cockpit UI for docker containers";
            license = licenses.lgpl21;
            homepage = "https://github.com/pk5ls20/cockpit-docker-upstream-mrevjd";
            platforms = platforms.linux;
            maintainers = with maintainers; [ redxtech ];
          };
        };
    };
}
