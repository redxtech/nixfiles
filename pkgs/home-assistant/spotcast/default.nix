{ lib, buildHomeAssistantComponent, fetchFromGitHub }:

buildHomeAssistantComponent rec {
  owner = "fondberg";
  domain = "spotcast";
  version = "3.8.1";

  src = fetchFromGitHub {
    inherit owner;
    repo = domain;
    rev = "v${version}";
    hash = "sha256-Z+H3H64fhwdJQ2+7xfx2oBzWRMdDtm/fSBJkHOUd9LY=";
  };

  dontBuild = true;

  meta = with lib; {
    changelog = "https://github.com/fondberg/spotcast/releases/tag/v${version}";
    description =
      "Home assistant custom component to start Spotify playback on an idle chromecast device as well as control spotify connect devices";
    homepage = "https://github.com/fondberg/spotcast";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.asl20;
  };
}
