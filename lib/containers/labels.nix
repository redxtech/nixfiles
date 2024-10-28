{ lib, ... }:

rec {
  # homepage dashboard labels
  mkHomepage = { container ? null, ... }@service:
    let
      inherit (lib.attrsets) attrsToList hasAttr;
      inherit (builtins) filter listToAttrs map;

      labelsNoWidget = filter (l: l.name != "widget") (attrsToList service);
      labelsWidget =
        if hasAttr "widget" service then (attrsToList service.widget) else [ ];

      attrToLabel = { name, value }:
        let labelName = if name == "desc" then "description" else name;
        in {
          name = "homepage.${labelName}";
          value = toString value;
        };

      attrToWidget = { name, value }: {
        name = "homepage.widget.${name}";
        value = toString value;
      };

      mainLabels = listToAttrs (map attrToLabel labelsNoWidget);
      widgetLabels = listToAttrs (map attrToWidget labelsWidget);
    in mainLabels // widgetLabels;

  # traefik labels
  traefik = address: rec {
    mkTLstr = name: type: "traefik.http.${type}.${name}"; # make traefik label
    mkTLRstr = name: "${mkTLstr name "routers"}"; # make traefik router label
    mkTLSstr = name: "${mkTLstr name "services"}"; # make traefik router label
    mkTLHstr = name: "${mkTLstr name "middlewares"}.headers"; # middleware label
    mkLabels = name: {
      "traefik.enable" = "true";
      "${mkTLRstr name}.rule" = "Host(`${name}.${address}`)";
      "${mkTLRstr name}.entrypoints" = "websecure";
      "${mkTLRstr name}.tls" = "true";
      "${mkTLRstr name}.tls.certresolver" = "cloudflare";
    };
    mkLabelsPort = name: port:
      (mkLabels name) // {
        "${mkTLSstr name}.loadbalancer.server.port" = "${toString port}";
      };

    # combined labels
    mkAllLabels = name: service: (mkLabels name) // mkHomepage service;
    mkAllLabelsPort = name: port: service:
      mkLabelsPort name port // mkHomepage service;
  };
}
