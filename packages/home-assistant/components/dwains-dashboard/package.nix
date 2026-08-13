{
  perSystem =
    {
      pkgs,
      lib,
      packageUpdateScripts,
      ...
    }:
    {
      packages.home-assistant-components-dwains-dashboard =
        let
          inherit (pkgs)
            buildHomeAssistantComponent
            fetchFromGitHub
            ;
        in
        buildHomeAssistantComponent rec {
          owner = "dwainscheeren";
          domain = "dwains_dashboard";
          version = "3.10.0";

          src = fetchFromGitHub {
            inherit owner;
            repo = "dwains-lovelace-dashboard";
            rev = "v${version}";
            hash = "sha256-JgpzISVu1punpKPLhPUQDUXTGsfyMpM1K9rzrjSSDkY=";
          };

          passthru.updateScript = packageUpdateScripts.githubSource {
            file = "packages/home-assistant/components/dwains-dashboard/package.nix";
            packageName = "home-assistant-components-dwains-dashboard";
            inherit owner;
            repo = "dwains-lovelace-dashboard";
          };

          meta = with lib; {
            changelog = "https://github.com/dwainscheeren/dwains-lovelace-dashboard/releases/tag/v${version}";
            description = "An fully auto generating Home Assistant UI dashboard for desktop, tablet and mobile by Dwains for desktop, tablet, mobile";
            homepage = "https://github.com/dwainscheeren/dwains-lovelace-dashboard";
            maintainers = with maintainers; [ redxtech ];
            license = licenses.cc-by-nc-nd-40;
          };
        };
    };
}
