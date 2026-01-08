{ lib, buildHomeAssistantComponent, fetchFromGitHub, python313Packages }:

let
  spotipy-old = python313Packages.buildPythonPackage rec {
    pname = "spotipy";
    version = "2.23.0";

    pyproject = true;
    buildSystem = with python313Packages; [ setuptools ];
    propagatedBuildInputs = with python313Packages; [
      setuptools
      requests
      responses
      redis
      six
    ];

    src = fetchFromGitHub {
      owner = "spotipy-dev";
      repo = "spotipy";
      tag = version;
      hash = "sha256-nF9rvWsndSePkhSwDU+MgXSNVSFrOUA/oSGoMc81wqk=";
    };
  };
in buildHomeAssistantComponent rec {
  owner = "fondberg";
  domain = "spotcast";
  version = "4.0.1"; # TODO: update to 5.0.0 after beta

  src = fetchFromGitHub {
    inherit owner;
    repo = domain;
    rev = "v${version}";
    hash = "sha256-xjs01S9yFbq3yfe1k+RxZXu3jzaSbXAIY34cl8Wrm7k=";
  };

  propagatedBuildInputs = [ spotipy-old ];

  dontBuild = true;
  doCheck = false; # TODO: use pythonRelaxDepsHook instead

  meta = with lib; {
    changelog = "https://github.com/fondberg/spotcast/releases/tag/v${version}";
    description =
      "Home assistant custom component to start Spotify playback on an idle chromecast device as well as control spotify connect devices";
    homepage = "https://github.com/fondberg/spotcast";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.asl20;
  };
}
