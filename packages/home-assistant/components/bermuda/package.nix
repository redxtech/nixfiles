{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-components-bermuda =
        let
          inherit (pkgs)
            buildHomeAssistantComponent
            fetchFromGitHub
            ;
        in
        buildHomeAssistantComponent rec {
          owner = "agittins";
          domain = "bermuda";
          version = "0.8.7";

          src = fetchFromGitHub {
            inherit owner;
            repo = domain;
            rev = "v${version}";
            hash = "sha256-UY4Cd0yt7yAbsYHr+KsLUan3dJSv80hhEPRmoy+8nO4=";
          };

          passthru.updateScript = packageUpdateScripts.githubSource {
            file = "packages/home-assistant/components/bermuda/package.nix";
            packageName = "home-assistant-components-bermuda";
            inherit owner;
            repo = domain;
          };

          meta = with lib; {
            changelog = "https://github.com/agittins/bermuda/releases/tag/v${version}";
            description = "Bermuda Bluetooth/BLE Triangulation / Trilateration for HomeAssistant";
            homepage = "https://github.com/agittins/bermuda";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.mit;
          };
        };
    };
}
