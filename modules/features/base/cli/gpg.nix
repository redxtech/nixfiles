{ inputs, self, ... }:

{
  den.aspects.gpg.homeManager =
    {
      config,
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

      # TODO: remove after https://github.com/nix-community/home-manager/pull/5720 is merged
      agentCfg = config.services.gpg-agent;
      gpgPkg = config.programs.gpg.package;
      gpgSshSupportStr = ''
        ${gpgPkg}/bin/gpg-connect-agent --quiet updatestartuptty /bye > /dev/null
      '';
      gpgInitStr = ''
        GPG_TTY="$(tty)"
        export GPG_TTY
      ''
      + lib.optionalString agentCfg.enableSshSupport gpgSshSupportStr;
      gpgFishInitStr = ''
        set -gx GPG_TTY (tty)
      ''
      + lib.optionalString agentCfg.enableSshSupport gpgSshSupportStr;
    in
    {
      home.packages = with pkgs; [ gpgme ] ++ pinentryPkgs;

      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
        sshKeys = [ "11148591F2B2026E9B2227BD5C7A1973A2838278" ];
        pinentry.package = if hasDisplay then pkgs.pinentry-gnome3 else pkgs.pinentry-curses;
        enableExtraSocket = true;

        enableBashIntegration = false;
        enableZshIntegration = false;
        enableFishIntegration = false;
      };

      # do it ourselves until PR merged
      programs.bash.initExtra = gpgInitStr;
      programs.zsh.initContent = gpgInitStr;
      programs.fish.interactiveShellInit = gpgFishInitStr;

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

      # link /run/user/$UID/gnupg to ~/.gnupg-sockets
      # so that SSH config does not have to know the UID
      systemd.user.services.link-gnupg-sockets = {
        Unit = {
          Description = "link gnupg sockets from /run to /home";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/ln -Tfs /run/user/%U/gnupg %h/.gnupg-sockets";
          ExecStop = "${pkgs.coreutils}/bin/rm $HOME/.gnupg-sockets";
          RemainAfterExit = true;
        };
        Install.WantedBy = [ "default.target" ];
      };

      # TODO: enable gpg in firefox ?
    };
}
