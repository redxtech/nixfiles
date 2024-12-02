{ imv, fetchpatch }:

imv.overrideAttrs (oldAttrs: {
  patches = [
    (fetchpatch {
      name = "make-mouse-wheel-action-configurable.patch";
      url =
        "https://lists.sr.ht/~exec64/imv-devel/%3C20240603152937.19125-2-hugo@whynothugo.nl%3E/raw";
      hash = "sha256-QGw2CRzsOq8lZTAqit5N9K6l2a+jrd5ng9cYG0k540o=";
    })
  ];
})
