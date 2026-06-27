{
  pkgs,
  stable,
  small,
}:

{
  # home assistant components
  home-assistant-bermuda = pkgs.callPackage ./home-assistant/components/bermuda { };
  home-assistant-browser-mod = pkgs.callPackage ./home-assistant/components/browser-mod { };
  home-assistant-dwains-dashboard = pkgs.callPackage ./home-assistant/components/dwains-dashboard { };
  home-assistant-iphonedetect = pkgs.callPackage ./home-assistant/components/iphonedetect { };
  home-assistant-node-red = pkgs.callPackage ./home-assistant/components/node-red { };
  home-assistant-pirate-weather = pkgs.callPackage ./home-assistant/components/pirate-weather { };
  home-assistant-spotcast = pkgs.callPackage ./home-assistant/components/spotcast { };
  home-assistant-tuya_local = pkgs.callPackage ./home-assistant/components/tuya_local { };
  home-assistant-var = pkgs.callPackage ./home-assistant/components/var { };

  # home assistant lovelace cards
  home-assistant-lovelace-bubble-card = pkgs.callPackage ./home-assistant/lovelace/bubble-card { };
  home-assistant-lovelace-card-tools = pkgs.callPackage ./home-assistant/lovelace/card-tools { };
  home-assistant-lovelace-config-template-card =
    pkgs.callPackage ./home-assistant/lovelace/config-template-card
      { };
  home-assistant-lovelace-custom-brand-icons =
    pkgs.callPackage ./home-assistant/lovelace/custom-brand-icons
      { };
  home-assistant-lovelace-ha-firemote = pkgs.callPackage ./home-assistant/lovelace/ha-firemote { };
  home-assistant-lovelace-horizon-card = pkgs.callPackage ./home-assistant/lovelace/horizon-card { };
  home-assistant-lovelace-layout-card = pkgs.callPackage ./home-assistant/lovelace/layout-card { };
  home-assistant-lovelace-waze-travel-time =
    pkgs.callPackage ./home-assistant/lovelace/waze-travel-time
      { };
}
