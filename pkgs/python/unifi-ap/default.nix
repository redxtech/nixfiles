{ lib, python3Packages, fetchurl }:

python3Packages.buildPythonPackage rec {
  pname = "unifi-ap";
  version = "0.0.1";
  format = "wheel";

  src = fetchurl {
    url =
      "https://files.pythonhosted.org/packages/dd/0f/9a84c3c20b43a821eae15ae5d732638f69ac086d252142e49249ad4bceef/unifi_ap-0.0.1-py3-none-any.whl";
    hash = "sha256-+qpWRqxSQX/4L19HPAe8P0fyJqAtnRVFBhJmCw0UUGk=";
  };

  build-system = with python3Packages; [ setuptools ];
  dependencies = with python3Packages; [ aiohttp paramiko ];
  pythonImportsCheck = [ "unifi_ap" ];

  meta = with lib; {
    changelog =
      "https://github.com/tofuSCHNITZEL/unifi_ap/releases/tag/v${version}";
    description = "Python API for UniFi accesspoints";
    homepage = "https://github.com/tofuSCHNITZEL/unifi_ap";
    license = licenses.mit;
    maintainers = with maintainers; [ redxtech ];
  };
}
