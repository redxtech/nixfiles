{ config, lib, pkgs, ... }: {
  # Wireless secrets stored through sops
  sops.secrets.wireless = {
    sopsFile = ../secrets.yaml;
    neededForUsers = true;
  };

  networking.wireless = {
    enable = true;
    fallbackToWPA2 = false;
    # Declarative
    environmentFile = config.sops.secrets.wireless.path;
    networks = {
      "JVGCLARO" = {
        psk = "@JVGCLARO@";
      };
      "Kartodrorealm" = {
        psk = "@KARTODROREALM@";
      };
      "Kartodrorealm-5G" = {
        psk = "@KARTODROREALM@";
      };
      "Marcos_2.4Ghz" = {
        pskRaw = "@MARCOS_24@";
      };
      "Marcos_5Ghz" = {
        pskRaw = "@MARCOS_50@";
      };
      "Misterio" = {
        pskRaw = "@MISTERIO@";
      };
      "VIVOFIBRA-FC41-5G" = {
        pskRaw = "@MARCOS_SANTOS_5G@";
      };
      "zoocha" = {
        pskRaw = "@ZOOCHA@";
      };
      "eduroam" = {
        auth = ''
          key_mgmt=WPA-EAP
          pairwise=CCMP
          group=CCMP TKIP
          eap=TTLS
          domain_suffix_match="semfio.usp.br"
          ca_path="${pkgs.cacert}/etc/ssl/certs"
          identity="10856803@usp.br"
          password="@EDUROAM@"
          phase2="auth=MSCHAPV2"
        '';
      };
    };

    # Imperative
    allowAuxiliaryImperativeNetworks = true;
    userControlled = {
      enable = true;
      group = "network";
    };
    extraConfig = ''
      update_config=1
    '';
  };

  # Ensure group exists
  users.groups.network = { };

  systemd.services.wpa_supplicant.preStart = "touch /etc/wpa_supplicant.conf";
}
