{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (pkgs)
        buildMozillaMach
        fetchFromGitHub
        fetchurl
        gitMinimal
        makeDesktopItem
        wrapThunderbird
        ;

      version = "153.1.0esr-bb7";
      thunderbirdVersion = "153.1.0esr";
      patchRevision = "08ab6c8d99cc33f25f566c841ac40fbb0804dd91";
      betterbirdPatches = fetchFromGitHub {
        owner = "Betterbird";
        repo = "thunderbird-patches";
        rev = patchRevision;
        hash = "sha256-+G2w31LQ97iDqgPoA8kSiW/VZJEUcyF4QQ3mbby8FKc=";
      };
      meta = {
        description = "Fine-tuned version of Mozilla Thunderbird";
        homepage = "https://www.betterbird.eu";
        changelog = "https://www.betterbird.eu/releasenotes/";
        license = lib.licenses.mpl20;
        maintainers = [ lib.maintainers.redxtech ];
        mainProgram = "betterbird";
        platforms = lib.platforms.linux;
      };

      betterbird-unwrapped-base =
        (buildMozillaMach {
          pname = "betterbird";
          inherit version meta;
          application = "comm/mail";
          applicationName = "Betterbird";
          binaryName = "betterbird";
          branding = "comm/mail/branding/betterbird";

          src = fetchurl {
            url = "mirror://mozilla/thunderbird/releases/${thunderbirdVersion}/source/thunderbird-${thunderbirdVersion}.source.tar.xz";
            sha512 = "3d6c82e1489b906e6cf73c3eeb7d7e23de6901a75c704176b996d183a889f24275214999155992789a57a713e6cd073e2752120c3b281136ed34f36f289fbcb4";
          };

          extraNativeBuildInputs = [ gitMinimal ];
          extraConfigureFlags = [ "--with-unsigned-addon-scopes=app,system" ];
          extraPreConfigure = ''
            export MOZ_APP_REMOTINGNAME=eu.betterbird.Betterbird
            export MOZ_NO_PIE_COMPAT=1
            export MOZ_TELEMETRY_REPORTING=
          '';
          # upstream distributes betterbird as patch queues on top of matching thunderbird sources.
          extraPostPatch = ''
            sed -i \
              -e '/content\/messenger\/buildconfig.html/d' \
              -e '/override chrome:\/\/global\/content\/buildconfig.html/d' \
              comm/mail/base/jar.mn

            applyPatchSeries() {
              local sourceRoot="$1"
              local series="$2"

              while IFS= read -r entry || [ -n "$entry" ]; do
                patchPath="''${entry%%#*}"
                patchPath="$(printf '%s' "$patchPath" | sed 's/[[:space:]]*$//')"
                [ -z "$patchPath" ] && continue

                echo "applying Betterbird patch $patchPath"
                git -C "$sourceRoot" apply --apply --whitespace=nowarn \
                  "${betterbirdPatches}/153/$patchPath"
              done < "${betterbirdPatches}/153/$series"
            }

            applyPatchSeries "$PWD" series-moz
            applyPatchSeries "$PWD/comm" series
          '';
        }).override
          {
            allowAddonSideload = true;
            crashreporterSupport = false;
            # keep local source builds within practical memory and time limits.
            enableDebugSymbols = false;
            geolocationSupport = false;
            ltoSupport = false;
            pgoSupport = false;
            requireSigning = false;
            webrtcSupport = false;
          };
      # betterbird keeps MOZ_APP_NAME as thunderbird while patching executable names independently.
      betterbird-unwrapped = betterbird-unwrapped-base.overrideAttrs (oldAttrs: {
        configureFlags = lib.filter (
          flag: !(lib.hasPrefix "--with-app-name=" flag)
        ) oldAttrs.configureFlags;
      });

      # the wrapper otherwise treats a non-thunderbird library name as a web browser.
      desktopItem = makeDesktopItem {
        name = "eu.betterbird.Betterbird";
        desktopName = "Betterbird";
        genericName = "Email Client";
        comment = "Read and write e-mails or RSS feeds, or manage tasks on calendars";
        exec = "betterbird %U";
        icon = "eu.betterbird.Betterbird";
        startupNotify = true;
        startupWMClass = "eu.betterbird.Betterbird";
        categories = [
          "Network"
          "Chat"
          "Email"
          "Feed"
          "GTK"
          "News"
        ];
        keywords = [
          "mail"
          "email"
          "e-mail"
          "messages"
          "rss"
          "calendar"
          "address book"
          "addressbook"
          "chat"
        ];
        mimeTypes = [
          "message/rfc822"
          "x-scheme-handler/mailto"
          "text/calendar"
          "text/x-vcard"
        ];
        actions = {
          ComposeMessage = {
            name = "Compose New Message";
            exec = "betterbird -compose";
          };
          OpenAddressBook = {
            name = "Open Address Book";
            exec = "betterbird -addressbook";
          };
          ProfileManager = {
            name = "Profile Manager";
            exec = "betterbird --ProfileManager";
          };
        };
      };
    in
    {
      packages.betterbird =
        (wrapThunderbird betterbird-unwrapped {
          pname = "betterbird";
          applicationName = "betterbird";
          icon = "eu.betterbird.Betterbird";
          libName = "betterbird";
          wmClass = "eu.betterbird.Betterbird";
          hasMozSystemDirPatch = true;
        }).overrideAttrs
          (oldAttrs: {
            inherit desktopItem meta;
            passthru = (oldAttrs.passthru or { }) // {
              inherit betterbird-unwrapped betterbirdPatches patchRevision;
            };
          });
    };
}
