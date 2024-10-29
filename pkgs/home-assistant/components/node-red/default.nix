{ lib, buildHomeAssistantComponent, python3Packages, fetchFromGitHub }:

buildHomeAssistantComponent rec {
  owner = "zachowj";
  domain = "nodered";
  version = "4.1.1";

  src = fetchFromGitHub {
    inherit owner;
    repo = "hass-node-red";
    rev = "v${version}";
    hash = "sha256-uiS1GC5YGARyAIOMj6zu92ZLSiRnr6O8R8EK53MCjzU=";
  };

  propagatedBuildInputs = with python3Packages; [ colorlog ];

  meta = with lib; {
    changelog =
      "https://github.com/zachowj/hass-node-red/releases/tag/v${version}";
    description =
      "Companion Component for node-red-contrib-home-assistant-websocket to help integrate Node-RED with Home Assistant Core";
    homepage = "https://github.com/zachowj/hass-node-red";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.mit;
  };
}
