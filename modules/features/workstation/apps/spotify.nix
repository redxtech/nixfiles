{ inputs, ... }:

{
  den.aspects.spotify = {
    homeManager =
      {
        config,
        inputs',
        pkgs,
        lib,
        ...
      }:
      {
        imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

        programs.spicetify =
          let
            spicePkgs = inputs'.spicetify-nix.legacyPackages;
          in
          {
            enable = true;
            wayland = true;

            enabledExtensions = with spicePkgs.extensions; [
              bookmark
              keyboardShortcut
              shuffle

              # community extensions
              beautifulLyrics
              betterGenres
              coverAmbience
              fullAlbumDate
              fullAppDisplayMod
              goToSong
              groupSession
              hidePodcasts
              lastfm
              # oldSidebar
              playingSource
              playlistIcons
              playNext
              powerBar
              seekSong
              sessionStats
              showQueueDuration
              skipStats
              songStats
            ];

            enabledCustomApps = with spicePkgs.apps; [
              lyricsPlus
              ncsVisualizer
              newReleases
            ];
          };

        # tui for spotify
        programs.spotify-player = {
          enable = true;

          settings = {
            playback_window_position = "Bottom";
            copy_command.command = lib.getExe' pkgs.wl-clipboard "wl-copy";
            border_type = "Rounded";

            notify_streaming_only = true;
            enable_streaming = "DaemonOnly";

            # app's default client_id
            client_id = "46e5005a11c34100bf0af93e78e21c9b";
            client_id_command = {
              command = lib.getExe' pkgs.coreutils "cat";
              args = [ config.sops.secrets.spotify-player-client-id.path ];
            };

            default_device = "spotify-player";
            device = {
              name = "spotify-player";
              device_type = "speaker";
              volume = 70;
              bitrate = 320;
              audio_cache = true;
              normalize = false;
              autoplay = true;
            };
          };

          keymaps = [
            {
              command = "FocusNextWindow";
              key_sequence = "C-l";
            }
            {
              command = "FocusPreviousWindow";
              key_sequence = "C-h";
            }
          ];
        };

        services.spotifyd = {
          enable = true;

          settings = {
            global = {
              # TODO: do we need to login for this to work?

              # username = "redxtech";
              # password_cmd = "${pkgs.coreutils}/bin/cat ${config.xdg.configHome}/spotify-tui/spotify.txt";

              use_mpris = true;
              backend = "pulseaudio"; # TODO: try "pipe"

              device_type = "computer";
              device_name = "desktop-spotifyd";

              bitrate = 320;
            };
          };
        };

        sops.secrets.spotify-player-client-id.sopsFile = ../../../../secrets/users/gabe/secrets.yaml;
      };
  };

  flake-file.inputs.spicetify-nix = {
    url = "github:Gerg-L/spicetify-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
