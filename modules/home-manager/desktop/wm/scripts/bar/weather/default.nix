{ writers, writeShellApplication, python3Packages, coreutils }:

let
  script = writers.writePython3Bin "weather" {
    libraries = with python3Packages; [ requests ];
  } (builtins.readFile ./weather-bar.py);
in writeShellApplication {
  name = "weather-bar";
  runtimeInputs = [ coreutils ];
  excludeShellChecks = [ "SC2155" ];
  text = ''
    export OPENWEATHER_API_KEY="$(cat ~/.config/secrets/openweathermap.txt)" 
    exec ${script}/bin/weather -u metric "$@"
  '';
}

