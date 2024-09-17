{ lib, buildHomeAssistantComponent, fetchFromGitHub }:

buildHomeAssistantComponent rec {
  owner = "dwainscheeren";
  domain = "dwains_dashboard";
  version = "3.7.1";

  src = fetchFromGitHub {
    inherit owner;
    repo = "dwains-lovelace-dashboard";
    rev = "v${version}";
    hash = "sha256-KB5lJkABsEH7eSK4WMldW+WevfH0EjCy3T4NEA3zLrM=";
  };

  meta = with lib; {
    changelog =
      "https://github.com/dwainscheeren/dwains-lovelace-dashboard/releases/tag/v${version}";
    description =
      "An fully auto generating Home Assistant UI dashboard for desktop, tablet and mobile by Dwains for desktop, tablet, mobile";
    homepage = "https://github.com/dwainscheeren/dwains-lovelace-dashboard";
    maintainers = with maintainers; [ redxtech ];
    license = licenses.cc-by-nc-nd-40;
  };
}
