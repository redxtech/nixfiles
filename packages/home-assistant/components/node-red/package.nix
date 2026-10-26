{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-components-node-red =
        let
          inherit (pkgs)
            buildHomeAssistantComponent
            fetchFromGitHub
            python314
            ;
        in
        buildHomeAssistantComponent rec {
          owner = "zachowj";
          domain = "nodered";
          version = "4.3.2";

          src = fetchFromGitHub {
            inherit owner;
            repo = "hass-node-red";
            rev = "v${version}";
            hash = "sha256-zEiz/2RKzpHIpS7n1w8RghlXNRwwBEGasquOBxvWM9I=";
          };

          passthru.updateScript = packageUpdateScripts.githubSource {
            file = "packages/home-assistant/components/node-red/package.nix";
            packageName = "home-assistant-components-node-red";
            inherit owner;
            repo = "hass-node-red";
          };

          propagatedBuildInputs = with python314.pkgs; [ colorlog ];

          meta = with lib; {
            changelog = "https://github.com/zachowj/hass-node-red/releases/tag/v${version}";
            description = "Companion Component for node-red-contrib-home-assistant-websocket to help integrate Node-RED with Home Assistant Core";
            homepage = "https://github.com/zachowj/hass-node-red";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.mit;
          };
        };
    };
}
