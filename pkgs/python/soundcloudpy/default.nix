{ lib, python3Packages, fetchFromGitHub }:

python3Packages.buildPythonPackage rec {
  pname = "soundcloudpy";
  version = "0.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "music-assistant";
    repo = "SoundcloudPy";
    rev = "v${version}";
    hash = "sha256-h6ItbV4sz4ml8xoG+vss4/IloDNFpajGpxP8s55/540=";
  };

  build-system = with python3Packages; [ setuptools ];
  dependencies = with python3Packages; [ aiohttp ];
  pythonImportsCheck = [ "soundcloudpy" ];

  meta = with lib; {
    changelog =
      "https://github.com/music-assistant/SoundcloudPy/releases/tag/v${version}";
    description = "Soundcloud API-V2 Python Client";
    homepage = "https://github.com/music-assistant/SoundcloudPy";
    license = licenses.asl20;
    maintainers = with maintainers; [ redxtech ];
  };
}
