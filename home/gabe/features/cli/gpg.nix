{ pkgs, config, lib, ... }:

{
  home.packages = with pkgs;
    if config.gtk.enable then [ gcr pinentry-gnome3 ] else [ pinentry-curses ];

  services.gpg-agent = {
    enable = false;
    enableSshSupport = true;
    sshKeys = [ "11148591F2B2026E9B2227BD5C7A1973A2838278" ];
    pinentryPackage =
      if config.gtk.enable then pkgs.pinentry-gnome3 else pkgs.pinentry-curses;
    enableExtraSocket = true;
  };

  programs.gpg = {
    enable = true;
    settings = { trust-model = "tofu+pgp"; };
    publicKeys = [{
      source = ../../pgp.asc;
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
}
# vim: filetype=nix
