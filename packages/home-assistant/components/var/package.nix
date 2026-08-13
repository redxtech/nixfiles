{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-components-var =
        let
          inherit (pkgs)
            buildHomeAssistantComponent
            fetchFromGitHub
            ;
        in
        buildHomeAssistantComponent rec {
          owner = "snarky-snark";
          domain = "var";
          version = "0.15.5";

          src = fetchFromGitHub {
            inherit owner;
            repo = "home-assistant-variables";
            rev = "v${version}";
            hash = "sha256-Mrrob3P1tY0EvGWVybTFRe7JsxsA/JUXSLbNPDPm5ro=";
          };

          passthru.updateScript = packageUpdateScripts.githubSource {
            file = "packages/home-assistant/components/var/package.nix";
            packageName = "home-assistant-components-var";
            inherit owner;
            repo = "home-assistant-variables";
          };

          dontBuild = true;

          meta = with lib; {
            changelog = "https://github.com/snarky-snark/home-assistant-variables/releases/tag/v${version}";
            description = "A custom Home Assistant component for declaring and setting generic variable entities dynamically.";
            homepage = "https://github.com/snarky-snark/home-assistant-variables";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.asl20;
          };
        };
    };
}
