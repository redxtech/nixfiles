{ writers, python3Packages }:

writers.writePython3Bin "spotify-volume" {
  libraries = with python3Packages; [ pulsectl-asyncio dbus-next ];
} (builtins.readFile ./spotify-volume.py)

