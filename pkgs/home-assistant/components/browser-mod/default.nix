{ lib, buildHomeAssistantComponent, fetchFromGitHub }:

buildHomeAssistantComponent rec {
  owner = "thomasloven";
  domain = "browser_mod";
  version = "2.3.1";

  src = fetchFromGitHub {
    inherit owner;
    repo = "hass-browser_mod";
    rev = "v${version}";
    hash = "sha256-JqbMgpXstUcQwLXPbIRtcg1OqNZycA0CFRW7G5G7eA8=";
  };

  meta = with lib; {
    changelog =
      "https://github.com/thomasloven/hass-browser_mod/releases/tag/v${version}";
    description =
      "A Home Assistant integration to turn your browser into a controllable entity and media player";
    homepage = "https://github.com/thomasloven/hass-browser_mod";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.mit;
  };
}
