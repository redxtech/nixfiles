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
          npmDepsHash = "sha256-X2fjj756X6dtwtKHN5pAi0yuQtnto/4CgcxU6HTIRLY=";
          makeCacheWritable = true;
          nodejs = pkgs.nodejs_22;

          nativeBuildInputs = [
            webpack-cli
            sass
          ];

          prePatch = ''
            substituteInPlace package.json \
              --replace-fail \
                '"node-sass": "^4.13.1"' \
                '"sass": "1.32.0"'
            substituteInPlace package-lock.json \
              --replace-fail '"node-sass": {' '"sass": {' \
              --replace-fail '"version": "4.14.1"' '"version": "1.32.0"' \
              --replace-fail \
                '"resolved": "https://registry.npmjs.org/node-sass/-/node-sass-4.14.1.tgz"' \
                '"resolved": "https://registry.npmjs.org/sass/-/sass-1.32.0.tgz"' \
              --replace-fail \
                '"integrity": "sha512-sjCuOlvGyCJS40R8BscF5vhVlQjNN069NtQ1gSxyK1u9iqvn6tf7O1R4GNowVZfiZUCRt5MmMs1xd+4V/7Yr0g=="' \
                '"integrity": "sha512-fhyqEbMIycQA4blrz/C0pYhv2o4x2y6FYYAH0CshBw3DXh5D5wyERgxw0ptdau1orc/GhNrhF7DFN2etyOCEng=="'
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
