{ lib, buildHomeAssistantComponent, fetchFromGitHub, python313Packages }:

buildHomeAssistantComponent rec {
  owner = "fondberg";
  domain = "spotcast";
  version = "4.0.0"; # TODO: update to 5.0.0 after beta

  src = fetchFromGitHub {
    inherit owner;
    repo = domain;
    rev = "v${version}";
    hash = "sha256-6KLxawikEWNybYJuq2tUpdOmxG9PgYky1tF3r7iz6OU=";
  };

  propagatedBuildInputs = with python313Packages; [ spotipy ];

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
