{ den, inputs, ... }:

{
  den.aspects.noctalia-plugins = {
    homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = with pkgs; [
          gpu-screen-recorder # for screen recorder plugin
          qt6.qtwebsockets # for home assistant plugin
        ];

        # programs.noctalia.settings = {
        #   plugins = {
        #     source = [
        #       {
        #         name = "official";
        #         kind = "git";
        #         location = "https://github.com/noctalia-dev/noctalia-plugins";
        #       }
        #       {
        #         name = "community";
        #         kind = "git";
        #         location = "https://github.com/noctalia-dev/community-plugins";
        #       }
        #       {
        #         name = "v5-port";
        #         kind = "git";
        #         location = "https://github.com/itsJai42/noctalia-v5-plugins";
        #       }
        #     ];
        #
        #     enabled = [
        #       "noctalia/screen_recorder"
        #       "noctalia/tailscale"
        #     ];
        #   };
        #
        #   plugin_settings = {
        #     "noctalia/screen_recorder" = { };
        #     "noctalia/tailscale" = { };
        #   };
        # };
      };
  };
}
