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

    lockOnRemove = {
      enable = mkOption {
        type = bool;
        default = false;
        description = "Lock the screen when the YubiKey is removed";
      };

      userID = mkOption {
        type = str;
        default = "1000";
        description = "The user ID to lock the screen for";
      };

      DISPLAY = mkOption {
        type = str;
        default = ":0";
        description = "The display to lock the screen on";
      };

      WAYLAND_DISPLAY = mkOption {
        type = str;
        default = "wayland-1";
        description = "The wayland display to lock the screen on";
      };
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

    # add udev rules for yubikey personalization
    services.udev.packages = with pkgs; [ yubikey-personalization ];

    # enable smartcard support
    hardware.gpgSmartcards.enable = true;

    # enable polkit to use yubikey for authentication
    security.polkit.enable = true;

    # enable u2f support in pam for login and sudo
    security.pam = {
      # enable u2f support in pam
      u2f = {
        enable = true;
        settings = {
          cue = true;
          authFile = "/etc/u2f-mappings";
        };
      };

      # enable u2f for login and sudo
      services = {
        login.u2fAuth = cfg.login;
        sudo.u2fAuth = cfg.sudo;
        # hyprlock.u2fAuth = cfg.login;
      };
    };

    # enable smartcard support
    services.pcscd.enable = true;

    # lock the screen when the yubikey is removed
    services.udev.extraRules = let
      authfilePrefix = "/run/user/${cfg.lockOnRemove.userID}/xauth_";
      scripts = {
        bspwm = pkgs.writeShellApplication {
          name = "lockscript.sh";
          runtimeEnv = { inherit (cfg.lockOnRemove) DISPLAY; };
          runtimeInputs = with pkgs; [ betterlockscreen ];
          text = ''
            # find the xauth file for the current user
            # by getting the first file that matches the prefix
            AUTHFILE=(${authfilePrefix}*)
            export XAUTHORITY="''${AUTHFILE[0]}"

            betterlockscreen --lock dimblur
          '';
        };
        hyprland = pkgs.writeShellApplication {
          name = "lockscript.sh";
          runtimeEnv = { inherit (cfg.lockOnRemove) WAYLAND_DISPLAY; };
          runtimeInputs = with pkgs; [ hyprlock ];
          text = ''
            # find xdg runtime dir for user
            USERID=$(id -u)
            XDG_RUNTIME_DIR="/run/user/$USERID"
            export XDG_RUNTIME_DIR

            hyprlock
          '';
        };
      };

      # choose the lockerscript based on the window manager
      lockscript = scripts.${config.desktop.wm};
      runCmd =
        "${pkgs.su}/bin/su - ${config.base.primaryUser} -c '${lockscript}/bin/lockscript.sh'";
    in mkIf cfg.lockOnRemove.enable ''
      # lock the screen when the yubikey is removed
      ACTION=="remove",\
        ENV{ID_BUS}=="usb",\
        ENV{PRODUCT}=="3/1050/407/110",\
        ENV{ID_REVISION}=="0512",\
        ENV{ID_MODEL_ID}=="0407",\
        ENV{ID_VENDOR_ID}=="1050",\
        ENV{ID_VENDOR}=="Yubico", RUN+="${runCmd}"
    '';

    # add u2f mappings if they are defined
    environment.etc."u2f-mappings".text =
      mkIf (builtins.length cfg.mappings > 0)
      (lib.concatStringsSep "\n" cfg.mappings);

    # enable desktop notifications for yubikey auth
    systemd.packages = [ pkgs.yubikey-touch-detector ];
    systemd.user = let
      serviceName = "yubikey-touch-detector";
      serviceConf = pkgs.writeText "service.conf" ''
        # show desktop notifications using libnotify
        YUBIKEY_TOUCH_DETECTOR_LIBNOTIFY=true
      '';
    in mkIf cfg.notify {
      services.${serviceName} = {
        description = "Detects when your YubiKey is waiting for a touch";
        requires = [ "${serviceName}.socket" ];
        serviceConfig = {
          ExecStart =
            "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector";
          EnvironmentFile = "${serviceConf}";
        };
        path = [ pkgs.gnupg ];
        requiredBy = [ "default.target" ];
        partOf = [ "${serviceName}.socket" ];
      };

      sockets.${serviceName} = {
        description =
          "Unix socket activation for YubiKey touch detector service";
        socketConfig = {
          ListenStream = "%t/${serviceName}.socket";
          RemoveOnStop = true;
        };
        wantedBy = [ "sockets.target" ];
      };
    };
  };
}
