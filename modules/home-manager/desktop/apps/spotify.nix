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
        fullAppDisplay
        keyboardShortcut
        shuffle

        # community extensions
        fullAlbumDate
        genre
        groupSession
        hidePodcasts
        lastfm
        playlistIcons
        playNext
        powerBar
        songStats
      ];
    };

    # install spotify if spicetify isn't enabled
    home.packages = with pkgs; lib.optional (!isSpiced) spotify;
  };
}
