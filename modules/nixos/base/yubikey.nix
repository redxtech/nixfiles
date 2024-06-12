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

    installGUIApps = mkOption {
      type = bool;
      default = true;
      description = "Install GUI applications for YubiKey management";
    };

    notify = mkOption {
      type = bool;
      default = true;
      description =
        "Enable desktop notifications when yubikey auth requires user interaction";
    };

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
    environment.systemPackages = with pkgs;
      [ yubikey-manager yubikey-personalization yubico-pam ]
      ++ lib.optionals cfg.installGUIApps [
        yubikey-manager-qt
        yubikey-personalization-gui
        yubioath-flutter
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

    # enable desktop notifications for yubikey auth
    systemd.user = let
      serviceName = "yubikey-touch-detector";
      serviceConf = pkgs.writeText "service.conf" ''
        # show desktop notifications using libnotify
        YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=true
      '';
    in mkIf cfg.notify {
      sockets.${serviceName} = {
        description =
          "Unix socket activation for YubiKey touch detector service";
        socketConfig = {
          ListenStream = "%t/${serviceName}.socket";
          RemoveOnStop = true;
        };
        wantedBy = [ "sockets.target" ];
      };
      services.${serviceName} = {
        description = "Detects when your YubiKey is waiting for a touch";
        requires = [ "${serviceName}.socket" ];
        serviceConfig = {
          ExecStart =
            "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector";
          EnvironmentFile = "${serviceConf}";
        };
        requiredBy = [ "default.target" ];
        partOf = [ "${serviceName}.socket" ];
      };
    };
  };
}
