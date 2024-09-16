{ lib, buildHomeAssistantComponent, fetchFromGitHub, python3Packages }:

let
  music-assistant =
    python3Packages.callPackage ../../python/music-assistant { };
in buildHomeAssistantComponent rec {
  owner = "music-assistant";
  version = "2024.9.1";
  domain = "mass";

  src = fetchFromGitHub {
    inherit owner;
    repo = "hass-music-assistant";
    rev = version;
    hash = "sha256-8YZ77SYv8hDsbKUjxPZnuAycLE8RkIbAq3HXk+OyAmM=";
  };

  patchPhase = ''
    substituteInPlace custom_components/mass/manifest.json \
      --replace-fail 'music-assistant==2.2.4' 'music-assistant==2.2.2'
  '';

  buildInputs = [ music-assistant ];
  propagatedBuildInputs = [ music-assistant ];

  meta = with lib; {
    changelog =
      "https://github.com/music-assistant/hass-music-assistant/releases/tag/${version}";
    description =
      "Turn your Home Assistant instance into a jukebox, hassle free streaming of your favorite media to Home Assistant media players.";
    homepage = "https://github.com/music-assistant/hass-music-assistant";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.asl20;
  };
}
