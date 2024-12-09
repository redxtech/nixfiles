{ writers, python3Packages, dbus-next, }:

writers.writePython3Bin "spotify-volume" {
  libraries = with python3Packages; [ pulsectl-asyncio dbus-next ];
} (builtins.readFile ./spotify-volume.py)

