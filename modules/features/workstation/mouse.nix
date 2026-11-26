{ den, self, ... }:

{
  den.aspects.mouse = {
    includes = [ den.aspects.keymasq ];

    nixos = {
      imports = [ self.nixosModules.mouse-debounce ];

      services.ratbagd.enable = true;

      services.mouse-debounce = {
        enable = true;
        # filter only the G604 passthrough without taking its input from keymasq
        devicePhys = "keymasq/passthrough/046d:4085/if02_mouse";
        settings.buttons."273" = 50;
      };

      programs.solaar = {
        enable = true;

        userService.enable = true;
        userService.batteryIcons = "symbolic";
      };
    };

    homeManager =
      { config, ... }:
      let
        configRoot = "${config.home.homeDirectory}/Code/nixfiles/modules/features/workstation/solaar";
        link = path: config.lib.file.mkOutOfStoreSymlink "${configRoot}/${path}";
      in
      {
        xdg.configFile = {
          "solaar/config.yaml".source = link "config.yaml";
          "solaar/rules.yaml".source = link "rules.yaml";
        };
      };
  };
}
