{ pkgs, config, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.cli;
in {
  config = mkIf cfg.enable {
    home.packages = with pkgs;
      if config.desktop.enable then [
        gcr
        pinentry-gnome3
      ] else
        [ pinentry-curses ];

    services.gpg-agent = {
      enable = false;
      enableSshSupport = true;
      sshKeys = [ "11148591F2B2026E9B2227BD5C7A1973A2838278" ];
      pinentryPackage = if config.desktop.enable then
        pkgs.pinentry-gnome3
      else
        pkgs.pinentry-curses;
      enableExtraSocket = true;
    };

    programs.gpg = {
      enable = true;
      settings = {
        personal-cipher-preferences = "AES256 AES192 AES";
        personal-digest-preferences = "SHA512 SHA384 SHA256";
        personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
        default-preference-list =
          "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
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
        # Display key origins and updates
        #with-key-origin
        require-cross-certification = true;
        no-symkey-cache = true;
        armor = true;
        use-agent = true;
        throw-keyids = true;
        # Keyserver URLs
        keyserver = [
          "hkps://keys.openpgp.org"
          "hkps://keyserver.ubuntu.com:443"
          "hkps://pgpkeys.eu"
          "hkps://pgp.circl.lu"
        ];
        # Enable key retrieval using WKD and DANE
        auto-key-locate = "wkd,dane,local";
        auto-key-retrieve = true;
        trust-model = "tofu+pgp";
        # Show expired subkeys
        #list-options show-unusable-subkeys
      };

      scdaemonSettings.disable-ccid = true;

      publicKeys = [{
        source = ../../../home/gabe/keys/pgp.asc;
        trust = 5;
      }];
    };

    systemd.user.services = {
      # Link /run/user/$UID/gnupg to ~/.gnupg-sockets
      # So that SSH config does not have to know the UID
      link-gnupg-sockets = {
        Unit = { Description = "link gnupg sockets from /run to /home"; };
        Service = {
          Type = "oneshot";
          ExecStart =
            "${pkgs.coreutils}/bin/ln -Tfs /run/user/%U/gnupg %h/.gnupg-sockets";
          ExecStop = "${pkgs.coreutils}/bin/rm $HOME/.gnupg-sockets";
          RemainAfterExit = true;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
  };
}
# vim: filetype=nix
