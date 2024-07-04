{ config, pkgs, lib, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    # notification daemon
    services.mako = {
      enable = true;

      format = ''<span weight="bold" size="x-large">%s - %a</span>\n%b'';

      font = "NotoSans Nerd Font Regular 12";
      width = 400;

      textColor = config.user-theme.purple;
      backgroundColor = "${config.user-theme.bg}B0";
      borderColor = config.user-theme.purple;
      borderSize = 2;
      padding = "8";
      margin = "5";
      iconPath = "${pkgs.papirus-icon-theme}/share/icons/Papirus-Dark";

      defaultTimeout = 5000; # 5 seconds
      maxVisible = -1;

      extraConfig = with config.user-theme; ''
        on-button-middle=dismiss-all

        [actionable]
        border-color=${cyan}

        [urgency=low]
        text-color=${fg}
        background-color=${bg-alt}B0
        border-color=${fg-alt}

        [urgency=critical]
        text-color=${fg}
        background-color=${red}B0
        border-color=${color5}
      '';
    };

  };
}
