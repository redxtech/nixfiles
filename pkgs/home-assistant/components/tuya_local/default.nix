{ lib, buildHomeAssistantComponent, fetchFromGitHub, python313Packages }:

let
  tinytuya-old = python313Packages.buildPythonPackage rec {
    pname = "tinytuya";
    version = "1.16.0";

    pyproject = true;
    build-system = with python313Packages; [ setuptools ];

    src = fetchFromGitHub {
      owner = "jasonacox";
      repo = "tinytuya";
      tag = "v${version}";
      hash = "sha256-K65kZjLa5AJG9FEYAs/Jf2UC8qiP7BkC8znHMHMYeg4=";
    };

    dependencies = with python313Packages; [ cryptography requests colorama ];

    # Tests require real network resources
    doCheck = false;
  };
in buildHomeAssistantComponent rec {
  owner = "make-all";
  domain = "tuya_local";
  version = "2025.1.0";

  src = fetchFromGitHub {
    inherit owner;
    repo = "tuya-local";
    tag = version;
    hash = "sha256-Bh/FGQBTdh0BtGiI83JhPS3xNAz4NhRqUGwZxxmZrqQ=";
  };

  dependencies = with python313Packages; [
    tinytuya-old
    tuya-device-sharing-sdk
  ];

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
