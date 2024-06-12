{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf;
  cfg = config.base.yubiauth;
in {
  options.base.yubiauth = let
    inherit (lib) mkOption mkEnableOption;
    inherit (lib.types) listOf str bool;
  in {
    enable = mkEnableOption "Enable YubiAuth";

    login = mkOption {
      type = bool;
      default = true;
      description = "Enable U2F authentication for login";
    };

    sudo = mkOption {
      type = bool;
      default = true;
      description = "Enable U2F authentication for sudo";
    };

    mappings = mkOption {
      type = listOf str;
      default = [ ];
      description = "List of mappings for U2F devices";
      example = ''
        [
          "<username>:<KeyHandle1>,<UserKey1>,<CoseType1>,<Options1>:<KeyHandle2>,<UserKey2>,<CoseType2>,<Options2>:..."
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    # yibikey required packages
    environment.systemPackages = with pkgs; [
      yubikey-personalization
      yubikey-manager
      yubico-pam
    ];

    # enable smartcard support
    hardware.gpgSmartcards.enable = true;

    # enable polkit to use yubikey for authentication
    security.polkit.enable = true;

    # enable u2f support in pam for login and sudo
    security.pam = {
      # enable u2f support in pam
      u2f = {
        enable = true;
        cue = true;
        authFile = "/etc/u2f-mappings";
      };

      # enable u2f for login and sudo
      services = {
        login.u2fAuth = cfg.login;
        sudo.u2fAuth = cfg.sudo;
      };
    };

    # add u2f mappings if they are defined
    environment.etc."u2f-mappings".text =
      mkIf (builtins.length cfg.mappings > 0)
      (lib.concatStringsSep "\n" cfg.mappings);
  };
}
