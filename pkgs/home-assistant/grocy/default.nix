{ lib, buildHomeAssistantComponent, python3Packages, fetchFromGitHub }:

let
  pygrocy = python3Packages.buildPythonPackage rec {
    pname = "pygrocy";
    version = "2.0.0";
    src = fetchFromGitHub {
      owner = "sebrut";
      repo = "pygrocy";
      rev = "v${version}";
      hash = "sha256-7ZJmeBqd9oPWW62AI6XKIyAJVzjspKrcQ/IZuf/EsxQ=";
    };
    doCheck = false;
  };
in buildHomeAssistantComponent rec {
  owner = "custom-components";
  domain = "grocy";
  version = "4.11.1";

  src = fetchFromGitHub {
    inherit owner;
    repo = domain;
    rev = "v${version}";
    hash = "sha256-gQaDXnREXIHWcpI1lLVwejrePPK5kk0FALBnGAta/Os=";
  };

  propagatedBuildInputs = with python3Packages; [ deprecation pygrocy ];

  meta = with lib; {
    changelog =
      "https://github.com/custom-components/grocy/releases/tag/${version}";
    description = "Custom Grocy integration for Home Assistant";
    homepage = "https://github.com/custom-components/grocy";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.asl20;
  };
}
