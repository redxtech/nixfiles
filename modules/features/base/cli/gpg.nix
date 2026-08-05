{
  den.aspects.gpg = {
    homeManager =
      {
        pkgs,
        lib,
        host,
        ...
      }:
      let
        inherit (host.settings.base) hasDisplay;

        pinentryPkgs =
          (lib.optionals hasDisplay (
            with pkgs;
            [
              gcr
              pinentry-gnome3
            ]
          ))
          ++ (lib.optionals (!hasDisplay) (with pkgs; [ pinentry-curses ]));
      in
      {
        home.packages = with pkgs; [ gpgme ] ++ pinentryPkgs;

        services.gpg-agent = {
          enable = true;
          enableSshSupport = true;
          enableExtraSocket = true;
          pinentry.package = if hasDisplay then pkgs.pinentry-gnome3 else pkgs.pinentry-curses;
        };

        programs.gpg = {
          enable = true;
          settings = {
            personal-cipher-preferences = "AES256 AES192 AES";
            personal-digest-preferences = "SHA512 SHA384 SHA256";
            personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
            default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
            cert-digest-algo = "SHA512";
            s2k-digest-algo = "SHA512";
            s2k-cipher-algo = "AES256";
            charset = "utf-8";
            no-comments = true;
            no-emit-version = true;
            no-greeting = true;
            keyid-format = "0xlong";
            list-options = "show-uid-validity";
            verify-options = "show-uid-validity";
            with-fingerprint = true;
            # display key origins and updates
            # with-key-origin
            require-cross-certification = true;
            no-symkey-cache = true;
            armor = true;
            use-agent = true;
            # disable recipient key ID in messages (breaks mailvelope)
            # throw-keyids = true;
            keyserver = [
              "hkps://keys.openpgp.org"
              "hkps://keyserver.ubuntu.com:443"
              "hkps://pgpkeys.eu"
              "hkps://pgp.circl.lu"
            ];
            # enable key retrieval using WKD and DANE
            auto-key-locate = "wkd,dane,local";
            auto-key-retrieve = true;
            trust-model = "tofu+pgp";
            # show expired subkeys
            # list-options = "show-unusable-subkeys";
          };

          scdaemonSettings.disable-ccid = true;

          publicKeys = [
            {
              source = ../../../users/gabe/pgp.asc;
              trust = 5;
            }
          ];
        };

        # TODO: enable gpg in firefox ?
      };
  };
}
