{ den, lib, ... }:

{
  den.aspects.gaming = {
    includes = [
      den.aspects.minecraft
      den.aspects.steam
    ];

    settings.extraLaunchers = lib.mkEnableOption "Enable extra launchers." // {
      default = true;
    };

    nixos = { host, pkgs, ... }: {
      hardware.steam-hardware.enable = true;
      hardware.xpadneo.enable = true;
      hardware.xone.enable = true;
      hardware.logitech.wireless.enable = true;
      hardware.logitech.wireless.enableGraphical = true;

      services.udev.packages = [ pkgs.game-devices-udev-rules ];

      environment.systemPackages =
        with pkgs;
        [
          # tools
          mangohud

          # controller compat
          SDL2
        ]
        ++ lib.optionals host.settings.gaming.extraLaunchers [
          heroic # epic games launcher
          umu-launcher # launch games with proton outside of steam
          faugus-launcher # gui for umu-launcher
          (lutris.override {
            extraPkgs = p: [
              p.proton-ge-bin
              p.umu-launcher
              p.wine
            ];
          })
        ];
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          eden # switch emulator
        ];
      };
  };
}
