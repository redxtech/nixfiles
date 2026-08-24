{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-components-pirate-weather =
        let
          inherit (pkgs)
            buildHomeAssistantComponent
            fetchFromGitHub
            python314
            ;

          python-forecastio = python314.pkgs.buildPythonPackage {
            pname = "python-forecastio";
            version = "1.4.0";

            pyproject = true;
            buildSystem = with python314.pkgs; [ setuptools ];
            propagatedBuildInputs = with python314.pkgs; [
              setuptools
              requests
              responses
            ];

            src = fetchFromGitHub {
              owner = "ZeevG";
              repo = "python-forecast.io";
              rev = "17bc91b6672b651db013adfae9d4584db56ef49a";
              hash = "sha256-ZINFP7vgyW53bgqpHabBJAKBqY5tHzTBrSoVl9hrmh0=";
            };
          };
        in
        buildHomeAssistantComponent rec {
          owner = "Pirate-Weather";
          domain = "pirateweather";
          version = "1.9.2";

          src = fetchFromGitHub {
            inherit owner;
            repo = "pirate-weather-ha";
            rev = "v${version}";
            hash = "sha256-mtvIwcngkbmaRLGTr3iaDY62SboSUQpYUTobHhT8S58=";
          };

          passthru.updateScript = packageUpdateScripts.githubSource {
            file = "packages/home-assistant/components/pirate-weather/package.nix";
            packageName = "home-assistant-components-pirate-weather";
            inherit owner;
            repo = "pirate-weather-ha";
          };

          propagatedBuildInputs = with python314.pkgs; [
            colorlog
            python-forecastio
          ];

          meta = with lib; {
            changelog = "https://github.com/Pirate-Weather/pirate-weather-ha/releases/tag/v${version}";
            description = "Replacement for the default Dark Sky Home Assistant integration using Pirate Weather";
            homepage = "https://github.com/Pirate-Weather/pirate-weather-ha";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.asl20;
          };
        };
    };
}
