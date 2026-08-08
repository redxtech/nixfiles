{
  den.aspects.voice-typing.homeManager =
    {
      self',
      host,
      lib,
      pkgs,
      ...
    }:
    {
      services.voxtype = {
        enable = true;
        package = self'.packages.voxtype-full;

        settings = {
          engine = if host.settings.workstation.isLaptop then "whisper" else "parakeet";
          state_file = "auto";

          hotkey = {
            key = "RIGHTCTRL";
            modifiers = [ ];
            mode = "toggle";
            enabled = true;
            model_modifier = "LEFTSHIFT";
          };

          audio = {
            device = "default";
            sample_rate = 16000;
            max_duration_secs = 60;
            pause_media = true;

            feedback = {
              enabled = true;
              volume = 0.7;
            };
          };

          whisper = {
            model = if host.settings.workstation.isLaptop then "small.en" else "large-v3-turbo";
            language = "en";
            translate = false;
            gpu_isolation = false;
            on_demand_loading = host.settings.workstation.isLaptop;
            flash_attention = false;
            eager_processing = false;
            mode = "local";
          };

          output = {
            mode = "type";
            fallback_to_clipboard = true;
            type_delay_ms = 0;
            auto_submit = false;
            shift_enter_newlines = false;
            pre_type_delay_ms = 0;

            notification = {
              on_recording_start = false;
              on_recording_stop = false;
              on_transcription = true;
              show_engine_icon = false;
            };
          };

          cohere = {
            model = "cohere-transcribe-q4f16";
            language = "en";
            on_demand_loading = false;
          };

          text = {
            spoken_punctuation = false;
            smart_auto_submit = true;
          };

          osd = {
            enabled = true;
            frontend = "gtk4";
            position = "bottom-center";
            width_px = 400;
            height_px = 64;
            margin_px = 24;
            top_margin = 0.85;
            opacity = 0.5;
            waveform_window_secs = 3.0;
            peak_decay_db_per_sec = 6.0;
            waveform_gain = 10.0;
          };

          parakeet = {
            streaming = true;
            model = "parakeet-unified-en-0.6b";
            on_demand_loading = false;
            streaming_chunk_secs = 0.32;
            streaming_left_context_secs = 5.6;
            streaming_right_context_secs = 0.32;
          };

          meeting = {
            enabled = false;
            diarization.enabled = true;
            audio.source = "both";
          };

          status.icon_theme = "emoji";
        };

        environment.PATH = lib.makeBinPath (
          with pkgs;
          [
            coreutils
            playerctl
            which
            wtype
            self'.packages.voxtype-full
          ]
        );
      };
    };
}
