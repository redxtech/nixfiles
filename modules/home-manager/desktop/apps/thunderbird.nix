{ config, lib, pkgs, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ betterbird birdtray thunderbird ];

    programs.thunderbird = {
      enable = true;

      profiles = {
        default = {
          isDefault = true;
          withExternalGnupg = true;
          settings = {
            "mail.openpgp.allow_external_gnupg" = true;
            "mail.compose.add_link_preview" = true;
            "mail.compose.autosaveinterval" = 1;
            "mail.folder.views.version" = 1;
            "mail.minimizeToTray" = true;
            "mail.openMessageBehavior.version" = 1;
          };
        };
      };
    };
  };
}
