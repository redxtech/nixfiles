{ den, ... }:

{
  den.aspects.email = {
    includes = [ den.aspects.thunderbird-credentials ];

    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        emailSecretsFile = ../../../../../secrets/users/gabe/email.yaml;
        sopsPasswordCommand = name: [
          (lib.getExe' pkgs.coreutils "cat")
          config.sops.secrets.${name}.path
        ];
      in
      {
        programs.thunderbird = {
          enable = true;

          profiles.gabe = {
            isDefault = true;
            withExternalGnupg = true;

            accountsOrder = [
              "fastmail"
              "super"
              "gabedunndev"
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

        accounts.email.accounts = {
          fastmail = {
            primary = true;
            realName = "Gabe";
            address = "gabe@sent.at";
            userName = "gabe@sent.at";
            imap.host = "imap.fastmail.com";
            imap.port = 993;
            smtp.host = "smtp.fastmail.com";
            smtp.port = 465;
            jmap.sessionUrl = "https://api.fastmail.com/jmap/session";
            passwordCommand = sopsPasswordCommand "fastmail";
            thunderbird.enable = true;
          };
          super = {
            realName = "Gabe Dunn";
            address = "gabe@super.fish";
            userName = "gabe@super.fish";
            imap.host = "imap.purelymail.com";
            imap.port = 993;
            passwordCommand = sopsPasswordCommand "super";
            thunderbird.enable = true;
          };
          gabedunndev = {
            realName = "Gabe Dunn";
            address = "gabe@gabedunn.dev";
            userName = "gabe@gabedunn.dev";
            imap.host = "imap.purelymail.com";
            imap.port = 993;
            passwordCommand = sopsPasswordCommand "gabedunndev";
            thunderbird.enable = true;
          };
          redxtech = {
            realName = "Gabe Dunn";
            address = "redxtechx@gmail.com";
            flavor = "gmail.com";
            folders = {
              inbox = "INBOX";
              sent = "[Gmail]/Sent Mail";
              drafts = "[Gmail]/Drafts";
              trash = "[Gmail]/Trash";
            };
            imap.authentication = "plain";
            smtp.authentication = "plain";
            passwordCommand = sopsPasswordCommand "redxtech";
            thunderbird.enable = true;
          };
        };

        sops.secrets =
          lib.genAttrs
            [
              "fastmail"
              "gabedunndev"
              "redxtech"
              "super"
            ]
            (_name: {
              sopsFile = emailSecretsFile;
            });
      };
  };
}
