{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-components-tuya-local =
        let
          inherit (pkgs)
            buildHomeAssistantComponent
            fetchFromGitHub
            python314
            ;

          tinytuya = python314.pkgs.buildPythonPackage rec {
            pname = "tinytuya";
            version = "1.20.0";

            pyproject = true;
            build-system = with python314.pkgs; [ setuptools ];

            src = fetchFromGitHub {
              owner = "jasonacox";
              repo = "tinytuya";
              tag = "v${version}";
              hash = "sha256-kyLRTfhTB8olZ48rUm+WtnuGZmCojnlUY4CeF+FADWg=";
            };

            dependencies = with python314.pkgs; [
              cryptography
              requests
              colorama
            ];

            # Tests require real network resources
            doCheck = false;
          };
        in
        buildHomeAssistantComponent rec {
          owner = "make-all";
          domain = "tuya_local";
          version = "2026.8.0";

          src = fetchFromGitHub {
            inherit owner;
            repo = "tuya-local";
            tag = version;
            hash = "sha256-EehiG62enkvYjFBMqFT+0mOXd5wbZxp5OEZUlDolKzg=";
          };

          passthru.updateScript = packageUpdateScripts.githubSource {
            file = "packages/home-assistant/components/tuya_local/package.nix";
            packageName = "home-assistant-components-tuya-local";
            inherit owner;
            repo = "tuya-local";
            tagPrefix = "";
          };

          dependencies = with python314.pkgs; [
            tinytuya
            tuya-device-sharing-sdk
          ];

          doCheck = false; # TODO: use pythonRelaxDepsHook instead

          meta = with lib; {
            description = "Local support for Tuya devices in Home Assistant";
            homepage = "https://github.com/make-all/tuya-local";
            changelog = "https://github.com/make-all/tuya-local/releases/tag/${version}";
            license = licenses.mit;
            maintainers = with maintainers; [ pathob ];
          };
        };
    };
}
