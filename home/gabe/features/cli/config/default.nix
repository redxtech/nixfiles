{ pkgs, lib, ... }:

{
  xdg.configFile = { "lyrics-in-terminal/lyrics.cfg".source = ./lyrics.cfg; };
}
