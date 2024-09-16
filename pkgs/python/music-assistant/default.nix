{ lib, python3Packages, fetchurl }:

python3Packages.buildPythonPackage rec {
  pname = "music-assistant";
  version = "2.2.2";
  format = "wheel";

  src = fetchurl {
    url =
      "https://files.pythonhosted.org/packages/45/10/150676aa745ce04fe78d789d8122cb250f15f91043065c735fc549fdbc6c/music_assistant-2.2.2-py3-none-any.whl";
    hash = "sha256-pBSXKacLaC9NHOnIBQj6tvAZRIrRmaIKXxPJjZuX9bI=";
  };

  build-system = with python3Packages; [ setuptools ];
  dependencies = with python3Packages; [ aiohttp mashumaro orjson ];
  pythonImportsCheck = [ "music_assistant" ];

  meta = with lib; {
    changelog =
      "https://github.com/music-assistant/server/releases/tag/${version}";
    description =
      "Music Assistant is a music library manager for various music sources which can easily stream to a wide range of supported players";
    longDescription = ''
      Music Assistant is a free, opensource Media library manager that connects to your streaming services and a wide
      range of connected speakers. The server is the beating heart, the core of Music Assistant and must run on an
      always-on device like a Raspberry Pi, a NAS or an Intel NUC or alike.
    '';
    homepage = "https://github.com/music-assistant/server";
    license = licenses.asl20;
    maintainers = with maintainers; [ hexa ];
  };
}
