{ lib, buildHomeAssistantComponent, fetchFromGitHub }:

buildHomeAssistantComponent rec {
  owner = "agittins";
  domain = "bermuda";
  version = "0.6.8";

  src = fetchFromGitHub {
    inherit owner;
    repo = domain;
    rev = "v${version}";
    hash = "sha256-IRx8jRXWHlAIWanCZlPfRU2Y2gcoTImIjBUuCNN1ktU=";
  };

  meta = with lib; {
    changelog = "https://github.com/agittins/bermuda/releases/tag/v${version}";
    description =
      "Bermuda Bluetooth/BLE Triangulation / Trilateration for HomeAssistant";
    homepage = "https://github.com/agittins/bermuda";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.mit;
  };
}
