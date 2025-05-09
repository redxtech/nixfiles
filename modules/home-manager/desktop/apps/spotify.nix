{ config, pkgs, lib, ... }:

let
  cfg = config.desktop;
  isSpiced = cfg.spicetify.enable;
in {
  config = lib.mkIf cfg.enable {
    # use spicetify if enabled
    programs.spicetify = {
      enable = isSpiced;

      theme = pkgs.spicePkgs.themes.catppuccin;
      colorScheme = "mocha";

      # windowManagerPatch = true;

      enabledExtensions = with pkgs.spicePkgs.extensions; [
        bookmark
        keyboardShortcut
        shuffle

        # community extensions
        beautifulLyrics
        betterGenres
        fullAlbumDate
        fullAppDisplayMod
        goToSong
        groupSession
        hidePodcasts
        lastfm
        # oldSidebar
        playlistIcons
        # playNext
        powerBar
        seekSong
        showQueueDuration
        # skipStats
        songStats
      ];

      enabledCustomApps = with pkgs.spicePkgs.apps; [
        lyricsPlus
        ncsVisualizer
        newReleases
      ];
    };

    # install spotify if spicetify isn't enabled
    home.packages = with pkgs; lib.optional (!isSpiced) spotify;
  };
}
