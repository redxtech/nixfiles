{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonPackage rec {
  pname = "tekore";
  version = "5.5.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "felix-hilden";
    repo = "tekore";
    rev = "v${version}";
    hash = "sha256-Ryu8CUjDGGpxRtzlMFDJ1icNDFtjJL2r3igaL16gX8c=";
  };

  build-system = with python3Packages; [ setuptools ];
  dependencies = with python3Packages; [ httpx pydantic ];
  pythonImportsCheck = [ "tekore" ];

  meta = with lib; {
    changelog =
      "https://github.com/felix-hilden/tekore/releases/tag/v${version}";
    description = "Spotify Web API client for Python 3";
    homepage = "https://tekore.readthedocs.io";
    license = licenses.asl20;
    maintainers = with maintainers; [ redxtech ];
  };
}
