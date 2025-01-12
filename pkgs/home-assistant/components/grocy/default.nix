{ lib, buildHomeAssistantComponent, python313Packages, fetchFromGitHub
, fetchPypi, fetchpatch }:

let
  pygrocy2 = python313Packages.buildPythonPackage rec {
    pname = "pygrocy2";
    version = "2.4.0";
    src = fetchFromGitHub {
      owner = "flipper";
      repo = "pygrocy";
      tag = "v${version}";
      hash = "sha256-2YDu1G6rAJYVGoiopbYybenQGP1VIs4ULP69iVvuTgk=";
    };
    doCheck = false;
  };
in buildHomeAssistantComponent rec {
  owner = "custom-components";
  domain = "grocy";
  version = "2025.1.1";

  src = fetchFromGitHub {
    inherit owner;
    repo = domain;
    tag = version;
    hash = "sha256-g8VGVGgIPivxWk9vbvR90VgTB/VGfZhEtNOwIjdy04s=";
  };

  propagatedBuildInputs = with python313Packages; [ deprecation pygrocy2 ];

  meta = with lib; {
    changelog =
      "https://github.com/custom-components/grocy/releases/tag/v${version}";
    description = "Custom Grocy integration for Home Assistant";
    homepage = "https://github.com/custom-components/grocy";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.asl20;
  };
}
