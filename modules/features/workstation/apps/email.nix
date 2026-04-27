{
  den.aspects.email.homeManager = {
    programs.thunderbird = {
      enable = true;

      profiles.gabe = {
        isDefault = true;
        withExternalGnupg = true;

        accountsOrder = [
          "fastmail"
          "super"
          "redxtech"
        ];

        # TODO: add more settings
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

    # TODO: add passwords somehow
    accounts.email.accounts = {
      fastmail = {
        thunderbird.enable = true;
        primary = true;
        address = "gabe@sent.at";
        userName = "gabe@sent.at";
        imap.host = "imap.fastmail.com";
        imap.port = 993;
        realName = "Gabe";
      };
      super = {
        thunderbird.enable = true;
        address = "gabe@super.fish";
        userName = "gabe@super.fish";
        imap.host = "imap.purelymail.com";
        imap.port = 993;
        realName = "Gabe Dunn";
      };
      redxtech = {
        thunderbird.enable = true;
        address = "redxtechx@gmail.com";
        flavor = "gmail.com";
        realName = "Gabe Dunn";
      };
    };
  };
}
