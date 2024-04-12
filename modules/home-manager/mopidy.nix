{ inputs, config, pkgs, lib, ... }:

let
  inherit (lib) types mkIf mkOption;
  cfg = config.mopidy;
in {
  options.mopidy = with types; {
    enable = mkOption {
      default = false;
      description = "Enable the service";
    };

    settings = mkOption {
      type = attrs;
      default = { };
      description = "Mopidy configuration";
    };

    extraConfigFiles = mkOption {
      type = listOf str;
      default = [ ];
      description = "Extra configuration files to include";
    };
  };

  config = mkIf cfg.enable {
    services.mopidy = {
      inherit (cfg) enable extraConfigFiles;

      extensionPackages = with pkgs; [
        mopidy-iris

        mopidy-notify
        mopidy-scrobbler

        mopidy-bandcamp
        # mopidy-jellyfin
        mopidy-mpris
        mopidy-soundcloud
        mopidy-spotify
      ];

      settings = {
        core.restore_state = true;
        mpd.enabled = false;
        notify.enabled = true;
        spotify.bitrate = 320;
        bandcamp.discover_tags =
          "Hyperpop, EDM, Electronic, Glitchcore, Drum & Bass, Hip-Hop, Pop";
        http.hostname = "0.0.0.0";
        iris = rec {
          country = "CA";
          locale = "en_${country}";
          snapcast_enabled = false;
        };
      } // cfg.settings;
    };
  };
}
