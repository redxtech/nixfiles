{ lib, ... }:

{
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

  # TODO: traefik labels
}
