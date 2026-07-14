{ lib, ... }:

{
  den.aspects.yubikey = {
    nixos =
      {
        inputs',
        host,
        config,
        pkgs,
        ...
      }:
      {
        # nixos module to configure yubikey u2f mappings
        options.yubikey.mappings = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          apply = lib.mapAttrsToList (name: value: { inherit name value; });
          example = {
            "<username>" =
              "<KeyHandle1>,<UserKey1>,<CoseType1>,<Options1>:<KeyHandle2>,<UserKey2>,<CoseType2>,<Options2>:...";
          };
          description = "U2F mappings keyed by user name.";
        };

        config = {
          services.udev.packages = [ pkgs.yubikey-personalization ];

          # enable smartcard support
          hardware.gpgSmartcards.enable = true;
          services.pcscd.enable = true;

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

            services = {
              login.u2fAuth = host.settings.base.hasDisplay;
              sudo.u2fAuth = true;
            };
          };

          # add u2f mappings if they are defined
          environment.etc."u2f-mappings".text = lib.mkIf (builtins.length config.yubikey.mappings > 0) (
            lib.concatMapStringsSep "\n" ({ name, value }: "${name}:${value}") config.yubikey.mappings
          );

          # lock the screen when the yubikey is removed
          services.udev.extraRules =
            let
              lockNoctalia = pkgs.writeShellApplication {
                name = "lockscript.sh";
                # TODO: do we need WAYLAND_DISPLAY?
                runtimeEnv.WAYLAND_DISPLAY = "wayland-1";
                runtimeInputs = [ inputs'.noctalia.packages.default ];
                text = ''
                  # find xdg runtime dir for user
                  USERID=$(id -u)
                  XDG_RUNTIME_DIR="/run/user/$USERID"
                  export XDG_RUNTIME_DIR

                  noctalia msg session lock
                '';
              };
              user = host.settings.base.primaryUser;
              runCmd = "${lib.getExe pkgs.su} - ${user} -c ${lib.getExe lockNoctalia}";
            in
            # TODO: test the lock on remove feature before enabling
            lib.mkIf (false && host.settings.base.hasDisplay) ''
              # lock the screen when the yubikey is removed
              ACTION=="remove",\
                ENV{ID_BUS}=="usb",\
                ENV{PRODUCT}=="3/1050/407/110",\
                ENV{ID_REVISION}=="0512",\
                ENV{ID_MODEL_ID}=="0407",\
                ENV{ID_VENDOR_ID}=="1050",\
                ENV{ID_VENDOR}=="Yubico", RUN+="${runCmd}"
            '';

          programs.yubikey-manager.enable = true;

          # notification when yubikey touch is required
          programs.yubikey-touch-detector.enable = host.settings.base.hasDisplay;
        };
      };

    homeManager = { host, pkgs, ... }: {
      home.packages =
        with pkgs;
        (
          [
            yubikey-personalization
            yubico-pam

            # use yubikey for secrets
            age-plugin-yubikey
          ]
          ++ lib.optional host.settings.base.hasDisplay yubioath-flutter
        );
    };
  };
}
