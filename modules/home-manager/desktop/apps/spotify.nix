{ pkgs, ... }:

{
  programs.spicetify = {
    enable = true;

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
}
