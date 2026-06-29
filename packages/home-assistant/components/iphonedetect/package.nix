{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.home-assistant-components-iphonedetect =
        let
          inherit (pkgs)
            buildHomeAssistantComponent
            fetchFromGitHub
            python314
            ;

          pyroute2-old = python314.pkgs.buildPythonPackage rec {
            pname = "pyroute2";
            version = "0.9.4";

            pyproject = true;
            buildSystem = with python314.pkgs; [ setuptools ];
            propagatedBuildInputs = with python314.pkgs; [
              setuptools
              requests
              responses
            ];

            src = fetchFromGitHub {
              owner = "svinota";
              repo = "pyroute2";
              tag = version;
              hash = "sha256-D603ZrLbc/6REx6X0bMvZzeyo0fgTsFL7J+iRTiQLgQ=";
            };
          };
        in
        buildHomeAssistantComponent rec {
          owner = "mudape";
          domain = "iphonedetect";
          version = "2.4.1";

          src = fetchFromGitHub {
            inherit owner;
            repo = domain;
            tag = version;
            hash = "sha256-AR3WVTcASueiJsumnfZ7jKs7aVs14E2WMdiAvNU6Y2Q=";
          };

          propagatedBuildInputs = [ pyroute2-old ];

          configurePhase = ''
            substituteInPlace custom_components/iphonedetect/manifest.json --replace-fail 'pyroute2==0.7.5' 'pyroute2==0.9.4'
          '';

          meta = with lib; {
            changelog = "https://github.com/mudape/iphonedetect/releases/tag/v${version}";
            description = "A custom component for Home Assistant to detect iPhones connected to local LAN, even if the phone is in deep sleep";
            homepage = "https://github.com/mudape/iphonedetect";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.mit;
          };
        };
    };
}
