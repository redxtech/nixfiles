{ lib, buildHomeAssistantComponent, python313Packages, fetchFromGitHub }:

let
  python-forecastio = python313Packages.buildPythonPackage {
    pname = "python-forecastio";
    version = "1.4.0";

    pyproject = true;
    buildSystem = with python313Packages; [ setuptools ];
    propagatedBuildInputs = with python313Packages; [
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
in buildHomeAssistantComponent rec {
  owner = "Pirate-Weather";
  domain = "pirateweather";
  version = "1.6.3";

  src = fetchFromGitHub {
    inherit owner;
    repo = "pirate-weather-ha";
    rev = "v${version}";
    hash = "sha256-jRe5KH3Rl2Vf22f7lI05p1IRecIrtH9ozsHh4qWHxP4=";
  };

  propagatedBuildInputs = with python313Packages; [
    colorlog
    python-forecastio
  ];

  meta = with lib; {
    changelog =
      "https://github.com/Pirate-Weather/pirate-weather-ha/releases/tag/v${version}";
    description =
      "Replacement for the default Dark Sky Home Assistant integration using Pirate Weather";
    homepage = "https://github.com/Pirate-Weather/pirate-weather-ha";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.asl20;
  };
}
