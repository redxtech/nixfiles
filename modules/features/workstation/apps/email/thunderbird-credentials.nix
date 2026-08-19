{
  den.aspects.thunderbird-credentials.homeManager =
    {
      config,
      pkgs,
      lib,
      self',
      ...
    }:
    let
      credentialSources = lib.filter (source: source.logins != [ ]) (
        lib.mapAttrsToList
          (
            name: account:
            assert lib.assertMsg (
              account.passwordCommand != [ ]
            ) "accounts.email.accounts.${name}.passwordCommand must contain a command";
            {
              command = lib.getExe' pkgs.coreutils "timeout";
              arguments = [
                "15s"
                (builtins.head account.passwordCommand)
              ]
              ++ builtins.tail account.passwordCommand;
              inherit name;
              logins =
                lib.optional (account.imap != null && account.userName != null) {
                  origin = "imap://${account.imap.host}";
                  username = account.userName;
                }
                ++ lib.optional (account.smtp != null && account.userName != null) {
                  origin = "smtp://${account.smtp.host}";
                  username = account.userName;
                };
            }
          )
          (
            lib.filterAttrs (
              _name: account: account.enable && account.thunderbird.enable && account.passwordCommand != null
            ) config.accounts.email.accounts
          )
      );

      credentialImporter = pkgs.writeText "betterbird-credential-importer.js" ''
        (() => {
          const credentialSources = ${builtins.toJSON credentialSources};
          const { classes: Cc, interfaces: Ci, utils: Cu } = Components;
          const { Subprocess } = ChromeUtils.importESModule(
            "resource://gre/modules/Subprocess.sys.mjs"
          );

          async function readAll(pipe, sourceName) {
            let output = "";
            let chunk;

            while ((chunk = await pipe.readString())) {
              output += chunk;
              if (output.length > 65536) {
                throw new Error(`credential command output is too large for ''${sourceName}`);
              }
            }

            return output;
          }

          async function readPassword(source) {
            const process = await Subprocess.call({
              command: source.command,
              arguments: source.arguments,
              stdout: "pipe",
              stderr: "pipe",
            });
            const [stdout, , { exitCode }] = await Promise.all([
              readAll(process.stdout, source.name),
              readAll(process.stderr, source.name),
              process.wait(),
            ]);

            if (exitCode !== 0) {
              throw new Error(
                `credential command failed for ''${source.name} with exit code ''${exitCode}`
              );
            }

            const password = stdout.replace(/\r?\n$/, "");
            if (!password) {
              throw new Error(`credential command returned no password for ''${source.name}`);
            }

            return password;
          }

          async function upsertLogin({ origin, username }, password) {
            const logins = await Services.logins.searchLoginsAsync({
              origin,
              httpRealm: origin,
            });
            const existing = logins.find(login => login.username === username);
            const login = Cc["@mozilla.org/login-manager/loginInfo;1"].createInstance(
              Ci.nsILoginInfo
            );
            login.init(origin, null, origin, username, password, "", "");

            if (!existing) {
              await Services.logins.addLoginAsync(login);
            } else if (existing.password !== password) {
              await Services.logins.modifyLoginAsync(existing, login);
            }
          }

          async function importCredentials() {
            await Promise.all(
              credentialSources.map(async source => {
                try {
                  const password = await readPassword(source);

                  for (const login of source.logins) {
                    await upsertLogin(login, password);
                  }
                } catch (error) {
                  Cu.reportError(error);
                }
              })
            );
          }

          function importBeforeStartup() {
            Services.obs.removeObserver(importBeforeStartup, "final-ui-startup");

            let finished = false;
            importCredentials()
              .catch(reason => {
                Cu.reportError(reason);
              })
              .finally(() => {
                finished = true;
              });

            // wait here so account startup cannot race credential import.
            Services.tm.spinEventLoopUntilOrQuit(
              "BetterbirdCredentialImporter",
              () => finished
            );
          }

          Services.obs.addObserver(importBeforeStartup, "final-ui-startup");
        })();
      '';

      betterbird = self'.packages.betterbird.override (old: {
        # credential import uses privileged login-manager and subprocess APIs.
        extraAutoConfig = (old.extraAutoConfig or "") + ''
          pref("general.config.sandbox_enabled", false);
        '';
        extraPrefsFiles = (old.extraPrefsFiles or [ ]) ++ [ credentialImporter ];
      });
    in
    {
      programs.thunderbird.package = betterbird;
    };
}
