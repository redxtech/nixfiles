{ lib }:

config:

let
  get = path: default: lib.attrByPath path default config;
  stringify = value: if value == null then null else toString value;

  containers = get [ "virtualisation" "oci-containers" "containers" ] { };
  containerUnits = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "docker-${name}" (
      let
        unit = get [ "systemd" "services" "docker-${name}" ] { };
      in
      {
        inherit (unit)
          after
          requires
          wantedBy
          wants
          ;
      }
    )
  ) containers;

  nativeServiceFields = {
    alloy = [
      "enable"
      "extraFlags"
      "configPath"
    ];
    coredns = [
      "enable"
      "config"
    ];
    esphome = [
      "enable"
      "address"
      "port"
      "openFirewall"
    ];
    flood = [
      "enable"
      "openFirewall"
      "port"
      "extraArgs"
    ];
    grafana = [
      "enable"
      "dataDir"
      "settings"
    ];
    hercules-ci-agent = [
      "enable"
      "settings"
    ];
    home-assistant = [
      "enable"
      "configDir"
      "lovelaceConfigWritable"
      "openFirewall"
      "config"
      "extraComponents"
    ];
    homepage-dashboard = [
      "enable"
      "listenPort"
      "openFirewall"
      "allowedHosts"
      "bookmarks"
      "docker"
      "environmentFile"
      "services"
      "settings"
      "widgets"
    ];
    influxdb2 = [
      "enable"
      "dataDir"
      "provision"
      "settings"
    ];
    loki = [
      "enable"
      "dataDir"
      "configuration"
      "extraFlags"
    ];
    mosquitto = [
      "enable"
      "dataDir"
      "listeners"
    ];
    navidrome = [
      "enable"
      "openFirewall"
      "settings"
    ];
    node-red = [
      "enable"
      "configFile"
      "openFirewall"
      "port"
      "withNpmAndGcc"
    ];
    plex = [
      "enable"
      "dataDir"
      "openFirewall"
      "group"
      "user"
    ];
    pocket-id = [
      "enable"
      "dataDir"
      "environmentFile"
      "settings"
    ];
    postgresql = [
      "enable"
      "dataDir"
      "ensureDatabases"
      "ensureUsers"
      "identMap"
      "authentication"
    ];
    prometheus = [
      "enable"
      "dataDir"
      "port"
      "extraFlags"
      "scrapeConfigs"
    ];
    stirling-pdf = [
      "enable"
      "environment"
    ];
    traefik = [
      "enable"
      "dataDir"
      "group"
      "environmentFiles"
      "staticConfigOptions"
      "dynamicConfigOptions"
    ];
    uptime-kuma = [
      "enable"
      "settings"
    ];
    zigbee2mqtt = [
      "enable"
      "dataDir"
      "settings"
    ];
  };

  identityNames = [
    "alloy"
    "data"
    "esphome"
    "grafana"
    "hass"
    "hercules-ci-agent"
    "influxdb2"
    "loki"
    "mosquitto"
    "navidrome"
    "node-red"
    "pocket-id"
    "postgres"
    "prometheus"
    "traefik"
  ];

  projectIdentity = name: {
    user =
      let
        value = get [ "users" "users" name ] null;
      in
      if value == null then
        null
      else
        {
          inherit (value)
            createHome
            description
            extraGroups
            group
            isNormalUser
            isSystemUser
            uid
            ;
          shell = stringify value.shell;
        };
    group =
      let
        value = get [ "users" "groups" name ] null;
      in
      if value == null then null else { inherit (value) gid members; };
  };

  projectSecret = value: {
    inherit (value)
      format
      group
      key
      mode
      neededForUsers
      owner
      path
      reloadUnits
      restartUnits
      ;
    sopsFile = stringify value.sopsFile;
  };

  projectCertificate = value: {
    inherit (value)
      domain
      extraDomainNames
      group
      reloadServices
      ;
    directory = stringify value.directory;
  };

  homeAssistant = get [ "services" "home-assistant" ] { };
  homeAssistantExtraPackages =
    if builtins.isList (homeAssistant.extraPackages or [ ]) then
      homeAssistant.extraPackages
    else
      homeAssistant.extraPackages (
        if homeAssistant.package ? python then
          homeAssistant.package.python.pkgs
        else
          homeAssistant.package.python3Packages
      );
in
{
  source = {
    commit = "23d6d3f2159581cc7a70ec1d12ea7d0ee90f1223";
    branch = "main";
  };

  host = {
    hostName = get [ "networking" "hostName" ] null;
    domain = get [ "network" "domain" ] null;
    address = get [ "network" "address" ] null;
    ip = get [ "network" "ip" ] null;
    timeZone = get [ "time" "timeZone" ] null;
    wheelNeedsPassword = get [ "security" "sudo" "wheelNeedsPassword" ] null;
    roots = get [ "nas" "paths" ] { };
  };

  identities = lib.genAttrs identityNames projectIdentity;

  containers = containers;
  containerUnits = containerUnits;

  nativeServices = lib.mapAttrs (
    name: fields: lib.filterAttrs (field: _: lib.elem field fields) (get [ "services" name ] { })
  ) nativeServiceFields;

  homeAssistantPackages = {
    extraComponents = homeAssistant.extraComponents or [ ];
    extraPackages = map lib.getName homeAssistantExtraPackages;
    customComponents = map lib.getName (homeAssistant.customComponents or [ ]);
    customLovelaceModules = map lib.getName (homeAssistant.customLovelaceModules or [ ]);
  };

  ingress = {
    routes = get [ "network" "finalServices" ] { };
    traefikStatic = get [ "services" "traefik" "staticConfigOptions" ] { };
    traefikDynamic = get [ "services" "traefik" "dynamicConfigOptions" ] { };
    certificates = lib.mapAttrs (_: projectCertificate) (get [ "security" "acme" "certs" ] { });
  };

  dns = {
    corefile = get [ "services" "coredns" "config" ] null;
    resolvconfUsesLocalResolver = get [ "networking" "resolvconf" "useLocalResolver" ] null;
  };

  firewall = {
    tcp = get [ "networking" "firewall" "allowedTCPPorts" ] [ ];
    udp = get [ "networking" "firewall" "allowedUDPPorts" ] [ ];
    tcpRanges = get [ "networking" "firewall" "allowedTCPPortRanges" ] [ ];
    udpRanges = get [ "networking" "firewall" "allowedUDPPortRanges" ] [ ];
  };

  secrets = lib.mapAttrs (_: projectSecret) (get [ "sops" "secrets" ] { });

  dockerNetworks = {
    names = [
      "booklore"
      "paperless"
      "tubearchivist"
    ];
    activationScript = get [ "system" "activationScripts" "mkDockerNetworks" "text" ] null;
  };

  monitoring = {
    alloyFlags = get [ "services" "alloy" "extraFlags" ] [ ];
    alloyConfigPath = stringify (get [ "services" "alloy" "configPath" ] null);
    ports = get [ "monitoring" "ports" ] { };
  };
}
