{ lib, buildHomeAssistantComponent, fetchFromGitHub, python313Packages }:

buildHomeAssistantComponent rec {
  owner = "make-all";
  domain = "tuya_local";
  version = "2025.1.0";

  src = fetchFromGitHub {
    inherit owner;
    repo = "tuya-local";
    tag = version;
    hash = "sha256-Bh/FGQBTdh0BtGiI83JhPS3xNAz4NhRqUGwZxxmZrqQ=";
  };

  dependencies = with python313Packages; [ tinytuya tuya-device-sharing-sdk ];

  doCheck = false; # TODO: use pythonRelaxDepsHook instead

  meta = with lib; {
    description = "Local support for Tuya devices in Home Assistant";
    homepage = "https://github.com/make-all/tuya-local";
    changelog =
      "https://github.com/make-all/tuya-local/releases/tag/${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ pathob ];
  };
}
