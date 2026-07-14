{ inputs, ... }:

{
  den.aspects.mouse = {
    nixos = {
      imports = [ inputs.solaar.nixosModules.default ];

      services.solaar.enable = true;

      hardware.logitech.wireless.enable = true;
      hardware.logitech.wireless.enableGraphical = true;
    };

    homeManager.xdg.configFile = {
      "solaar/rules.yaml".text = ''
        %YAML 1.3
        ---
        - Rule:
          - Key: [Forward Button, pressed]
          - KeyPress:
            - [Control_L, c]
            - click
        ...
        ---
        - Rule:
          - Key: [Back Button, pressed]
          - KeyPress:
            - [Control_L, v]
            - click
        ...
        ---
        - Rule:
          - Key: [Mouse Gesture Button, pressed]
          - KeyPress:
            - Super_L
            - depress
        - Rule:
          - Key: [Mouse Gesture Button, released]
          - KeyPress:
            - Super_L
            - release
        ...
        ---
        - Rule:
          - Key: [Smart Shift, pressed]
          - KeyPress:
            - f
            - click
        ...
      '';

      "solaar/config.yaml".text = ''
        - 1.1.19
        - _NAME: G604 Wireless Gaming Mouse
          _absent: [hi-res-scroll, lowres-scroll-mode, scroll-ratchet, scroll-ratchet-torque, smart-shift, thumb-scroll-invert, thumb-scroll-mode, report_rate_extended,
            pointer_speed, dpi_extended, speed-change, backlight, backlight_level, backlight_duration_hands_out, backlight_duration_hands_in, backlight_duration_powered,
            backlight-timed, rgb_control, rgb_zone_, brightness_control, per-key-lighting, fn-swap, reprogrammable-keys, persistent-remappable-keys, divert-keys,
            disable-keyboard-keys, force-sensing, crown-smooth, divert-crown, divert-gkeys, m-key-leds, mr-key-led, multiplatform, gesture2-gestures, gesture2-divert,
            gesture2-params, haptic-level, haptic-play, sidetone, equalizer, adc_power_management]
          _battery: 4096
          _modelId: B02440850000
          _sensitive: {hires-scroll-mode: false, hires-smooth-invert: ignore, hires-smooth-resolution: ignore}
          _serial: 39D2B23D
          _unitId: 39D2B23D
          _wpid: '4085'
          change-host: null
          dpi: 800
          hires-scroll-mode: false
          hires-smooth-invert: false
          hires-smooth-resolution: true
          led_control: 0
          onboard_profiles: 5
          report_rate: 1
        - _NAME: MX Master 3S
          _absent: [hi-res-scroll, lowres-scroll-mode, scroll-ratchet-torque, onboard_profiles, report_rate, report_rate_extended, pointer_speed, dpi_extended,
            speed-change, backlight, backlight_level, backlight_duration_hands_out, backlight_duration_hands_in, backlight_duration_powered, backlight-timed, led_control,
            led_zone_, rgb_control, rgb_zone_, brightness_control, per-key-lighting, fn-swap, persistent-remappable-keys, disable-keyboard-keys, force-sensing,
            crown-smooth, divert-crown, divert-gkeys, m-key-leds, mr-key-led, multiplatform, gesture2-gestures, gesture2-divert, gesture2-params, haptic-level,
            haptic-play, sidetone, equalizer, adc_power_management]
          _battery: 4100
          _modelId: B03400000000
          _sensitive: {divert-keys: true, dpi: true, hires-smooth-resolution: false, reprogrammable-keys: true, scroll-ratchet: false, smart-shift: true}
          _serial: B42DD628
          _unitId: B42DD628
          _wpid: B034
          change-host: null
          divert-keys: {82: 0, 83: 1, 86: 1, 195: 1, 196: 1}
          dpi: 800
          hires-scroll-mode: false
          hires-smooth-invert: false
          hires-smooth-resolution: false
          reprogrammable-keys: {80: 80, 81: 81, 82: 82, 83: 83, 86: 86, 195: 195, 196: 196}
          scroll-ratchet: 2
          smart-shift: 8
          thumb-scroll-invert: false
          thumb-scroll-mode: false
      '';
    };
  };

  flake-file.inputs.solaar = {
    url = "github:Svenum/Solaar-Flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
