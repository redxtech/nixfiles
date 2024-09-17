{ lib, buildHomeAssistantComponent, python3Packages, fetchFromGitHub }:

let
  python-forecastio = python3Packages.buildPythonPackage {
    pname = "python-forecastio";
    version = "1.4.0";
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
  version = "1.5.8";

  src = fetchFromGitHub {
    inherit owner;
    repo = "pirate-weather-ha";
    rev = "v${version}";
    hash = "sha256-l9QhQ5FQcoSBdtLnFjDV0S8KgiDQ7r+T55NKnTqwLr0=";
  };

  propagatedBuildInputs = with python3Packages; [ colorlog python-forecastio ];

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
