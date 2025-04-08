{ lib, fetchurl, buildPythonPackage, setuptools, aiohttp, paramiko }:

let version = "0.0.1";
in buildPythonPackage {
  pname = "unifi-ap";
  format = "wheel";
  inherit version;

  src = fetchurl {
    url =
      "https://files.pythonhosted.org/packages/dd/0f/9a84c3c20b43a821eae15ae5d732638f69ac086d252142e49249ad4bceef/unifi_ap-0.0.1-py3-none-any.whl";
    hash = "sha256-+qpWRqxSQX/4L19HPAe8P0fyJqAtnRVFBhJmCw0UUGk=";
  };

  build-system = [ setuptools ];
  dependencies = [ aiohttp paramiko ];
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
