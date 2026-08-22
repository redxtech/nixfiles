{ den, ... }:

{
  den.aspects.email = {
    includes = [ den.aspects.thunderbird-credentials ];

    homeManager =
      {
        self',
        config,
        lib,
        pkgs,
        ...
      }:
      let
        emailSecretsFile = ../../../../../secrets/users/gabe/email.yaml;
        tbkeysLite = self'.packages.tbkeys-lite;
        imapAccountUri = address: host: "imap://${lib.escapeURL address}@${host}";
        imapUri =
          address: host: folder:
          "${imapAccountUri address host}/${folder}";
        thunderbirdIdentitySettings =
          {
            address,
            host,
            archive,
            archivePickerMode ? "0",
            drafts ? "Drafts",
            sent ? "Sent",
            sentPickerMode ? "0",
            templates ? "Templates",
            externalGpg ? false,
          }:
          id:
          {
            "mail.identity.id_${id}.archive_folder" = imapUri address host archive;
            "mail.identity.id_${id}.archives_folder_picker_mode" = archivePickerMode;
            "mail.identity.id_${id}.draft_folder" = imapUri address host drafts;
            "mail.identity.id_${id}.drafts_folder_picker_mode" = "0";
            "mail.identity.id_${id}.fcc_folder" = imapUri address host sent;
            "mail.identity.id_${id}.fcc_folder_picker_mode" = sentPickerMode;
            "mail.identity.id_${id}.stationery_folder" = imapUri address host templates;
            "mail.identity.id_${id}.tmpl_folder_picker_mode" = "0";
          }
          // lib.optionalAttrs externalGpg {
            "mail.identity.id_${id}.is_gnupg_key_id" = true;
          };
        thunderbirdServerSettings =
          {
            address,
            host,
            junk,
            trash ? null,
          }:
          id:
          {
            "mail.server.server_${id}.moveOnSpam" = true;
            "mail.server.server_${id}.spamActionTargetAccount" = imapAccountUri address host;
            "mail.server.server_${id}.spamActionTargetFolder" = imapUri address host junk;
          }
          // lib.optionalAttrs (trash != null) {
            "mail.server.server_${id}.trash_folder_name" = trash;
          };
        sopsPasswordCommand = name: [
          (lib.getExe' pkgs.coreutils "cat")
          config.sops.secrets.${name}.path
        ];
      in
      {
        programs.thunderbird = {
          enable = true;

          policies."3rdparty".Extensions.${tbkeysLite.addonId} = {
            mainkeys = builtins.toJSON {
              "#" = "cmd:cmd_delete";
              a = "cmd:cmd_replyall";
              c = "func:MsgNewMessage";
              f = "cmd:cmd_forward";
              j = "cmd:cmd_nextMsg";
              k = "cmd:cmd_previousMsg";
              h = "cmd:cmd_archive";
              o = "cmd:cmd_openMessage";
              r = "cmd:cmd_reply";
              u = "tbkeys:closeMessageAndRefresh";
              x = "cmd:cmd_archive";
            };
            composekeys = builtins.toJSON { };
          };

          profiles.gabe = {
            isDefault = true;
            extensions = [ tbkeysLite ];
            withExternalGnupg = true;

            accountsOrder = [
              "fastmail"
              "super"
              "gabedunndev"
              "redxtech"
            ];

            settings = {
              "extensions.autoDisableScopes" = 0;
              "mail.closeToTray" = true;
              "mail.cloud_files.accounts.account1.displayName" = "Super Fish Send";
              "mail.cloud_files.accounts.account1.type" = "ext-send@tealdulcet.com";
              "mail.compose.add_link_preview" = true;
              "mail.compose.autosaveinterval" = 1;
              "mail.folder.views.version" = 1;
              "mail.imap.chunk_size" = 81920;
              "mail.imap.min_chunk_size_threshold" = 122880;
              "mail.minimizeToTray" = true;
              "mail.openMessageBehavior.version" = 1;
              "mail.openpgp.allow_external_gnupg" = true;
              "mail.shell.checkDefaultClient" = false;
              "mail.spam.manualMark" = true;
              "mail.startupMinimized" = true;
              "mailnews.customDBHeaders" =
                "x-send-later-at x-send-later-recur x-send-later-args x-send-later-cancel-on-reply x-send-later-uuid content-type";
              "mailnews.headers.extraAddonHeaders" = "autocrypt openpgp";
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
            folders.trash = "Archive";
            jmap.sessionUrl = "https://api.fastmail.com/jmap/session";
            passwordCommand = sopsPasswordCommand "fastmail";
            thunderbird = {
              enable = true;
              perIdentitySettings = thunderbirdIdentitySettings {
                address = "gabe@sent.at";
                host = "imap.fastmail.com";
                archive = "Archives";
                externalGpg = true;
              };
              settings = thunderbirdServerSettings {
                address = "gabe@sent.at";
                host = "imap.fastmail.com";
                junk = "Spam";
                trash = "Archive";
              };
            };
          };
          super = {
            realName = "Gabe Dunn";
            address = "gabe@super.fish";
            userName = "gabe@super.fish";
            imap.host = "imap.purelymail.com";
            imap.port = 993;
            smtp.host = "smtp.purelymail.com";
            smtp.port = 465;
            passwordCommand = sopsPasswordCommand "super";
            thunderbird = {
              enable = true;
              perIdentitySettings = thunderbirdIdentitySettings {
                address = "gabe@super.fish";
                host = "imap.purelymail.com";
                archive = "Archives";
                externalGpg = true;
              };
              settings = thunderbirdServerSettings {
                address = "gabe@super.fish";
                host = "imap.purelymail.com";
                junk = "Junk";
              };
            };
          };
          gabedunndev = {
            realName = "Gabe Dunn";
            address = "gabe@gabedunn.dev";
            userName = "gabe@gabedunn.dev";
            imap.host = "imap.purelymail.com";
            imap.port = 993;
            smtp.host = "smtp.purelymail.com";
            smtp.port = 465;
            passwordCommand = sopsPasswordCommand "gabedunndev";
            thunderbird = {
              enable = true;
              perIdentitySettings = thunderbirdIdentitySettings {
                address = "gabe@gabedunn.dev";
                host = "imap.purelymail.com";
                archive = "Archive";
                archivePickerMode = "1";
                externalGpg = true;
              };
              settings = thunderbirdServerSettings {
                address = "gabe@gabedunn.dev";
                host = "imap.purelymail.com";
                junk = "Junk";
              };
            };
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
            thunderbird = {
              enable = true;
              perIdentitySettings = thunderbirdIdentitySettings {
                address = "redxtechx@gmail.com";
                host = "imap.gmail.com";
                archive = "[Gmail]/All Mail";
                archivePickerMode = "1";
                sent = "[Gmail]/Sent Mail";
                sentPickerMode = "1";
              };
              settings = thunderbirdServerSettings {
                address = "redxtechx@gmail.com";
                host = "imap.gmail.com";
                junk = "Junk";
              };
            };
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
