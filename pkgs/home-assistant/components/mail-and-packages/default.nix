{ lib, buildHomeAssistantComponent, python313Packages, fetchFromGitHub
, customConfigDir ? "/config/homeassistant" }:

let
  python-resize-image = python313Packages.buildPythonPackage {
    pname = "python-resize-image";
    version = "2021-11-04";
    src = fetchFromGitHub {
      owner = "VingtCinq";
      repo = "python-resize-image";
      rev = "9c9a1f6d61abf3f5072ca0934963fcd75ed24c08";
      hash = "sha256-Emk/k8kzhFiWtpU7DOtqbrn5xAaJUT3yeZmnYmke2lQ=";
    };
    propagatedBuildInputs = with python313Packages; [
      beautifulsoup4
      dateparser
    ];
  };
in buildHomeAssistantComponent rec {
  owner = "moralmunky";
  domain = "mail_and_packages";
  version = "0.4.2";

  src = fetchFromGitHub {
    inherit owner;
    repo = "Home-Assistant-Mail-And-Packages";
    rev = version;
    hash = "sha256-5LBTlRlkSUx8DOY+F7UvUs4dzjZKdBdgnDUdK6DBdew=";
  };

  propagatedBuildInputs = with python313Packages; [
    imageio
    python-resize-image
  ];

  meta = with lib; {
    changelog =
      "https://github.com/moralmunky/Home-Assistant-Mail-And-Packages/releases/tag/v${version}";
    description =
      "Home Assistant integration providing day of package counts and USPS informed delivery images.";
    homepage =
      "https://github.com/moralmunky/Home-Assistant-Mail-And-Packages/";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.mit;
  };
}
