{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-components-browser-mod =
        let
          inherit (pkgs)
            buildHomeAssistantComponent
            fetchFromGitHub
            ;
        in
        buildHomeAssistantComponent rec {
          owner = "thomasloven";
          domain = "browser_mod";
          version = "3.4.1";

          src = fetchFromGitHub {
            inherit owner;
            repo = "hass-browser_mod";
            rev = "v${version}";
            hash = "sha256-thirjQ5YJS8e8uIhDGQ9cTNLhH3LJwJWrxrMTZaxcXw=";
          };

          passthru.updateScript = packageUpdateScripts.githubSource {
            file = "packages/home-assistant/components/browser-mod/package.nix";
            packageName = "home-assistant-components-browser-mod";
            inherit owner;
            repo = "hass-browser_mod";
          };

          meta = with lib; {
            changelog = "https://github.com/thomasloven/hass-browser_mod/releases/tag/v${version}";
            description = "A Home Assistant integration to turn your browser into a controllable entity and media player";
            homepage = "https://github.com/thomasloven/hass-browser_mod";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.mit;
          };
        };
    };
}
