{
  den.aspects.screen-recorder.homeManager =
    { pkgs, ... }:
    {
      programs.obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          obs-tuna # song information
          droidcam-obs # use android camera as a source
          obs-markdown # markdown source
          input-overlay # keyboard/gamepad input overlay
          obs-pipewire-audio-capture # audio capture
        ];
      };
    };
}
