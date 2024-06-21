{ imv, ... }:

imv.overrideAttrs (oldAttrs: {
  patches = [ ./patches/0001-mouse-wheel-action-configurable.patch ];
})
