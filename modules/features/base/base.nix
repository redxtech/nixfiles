{ den, lib, ... }:

{
  den.aspects.base = {
    includes = [
      den.aspects.cli
      den.aspects.nix-config
      den.aspects.root
      den.aspects.secrets
      den.aspects.ssh
      den.aspects.style
      den.aspects.tailscale
    ];

    settings.hasDisplay = lib.mkEnableOption "Whether the host has a display";

    nixos = {
      services.userborn.enable = true;

      i18n = {
        defaultLocale = "en_CA.UTF-8";
        extraLocales = [
          "en_CA.UTF-8/UTF-8"
          "en_US.UTF-8/UTF-8"
        ];
      };
    };

    homeManager = {
      home.language.base = "en_CA.UTF-8";

      systemd.user.startServices = "sd-switch";
    };
  };
}
