{ config, pkgs, lib, ... }:

let cfg = config.desktop.wm.hyprland;
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

    services.swaync = {
      enable = false;

      settings = {
        positionX = "right";
        positionY = "top";
        control-center-width = 460;
        control-center-margin-top = 20;
        control-center-margin-bottom = 20;
        control-center-margin-right = 20;
        control-center-margin-left = 20;

        notification-icon-size = 64;
        notification-body-image-height = 100;
        notification-body-image-width = 200;

        notification-window-width = 500;
        image-visibility = "when-available";
        transition-time = 200;

        widgets =
          [ "title" "dnd" "inhibitors" "mpris" "notifications" "buttons-grid" ];

        widget-config = {
          title = {
            text = "notifications";
            clear-all-button = true;
            button-text = "clear";
          };
          dnd.text = "do not disturb";
          mpris = {
            image-size = 100;
            image-radius = 4;
          };
          buttons-grid.actions = let
            scripts = config.desktop.wm.scripts;
            systemctl = "${pkgs.systemd}/bin/systemctl";
          in [
            {
              label = "󰍛";
              command = scripts.general.hdrop-btop;
            }
            {
              label = "󰛳";
              command = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
            }
            {
              label = "󰂯";
              command = "${pkgs.blueman}/bin/blueman-manager";
            }
            {
              label = "";
              command =
                "${pkgs.flatpak}/bin/flatpak run io.github.seadve.Kooha";
            }
            {
              label = "";
              command = scripts.wm.lock;
            }
            {
              label = "󰑓";
              command = "${pkgs.hyprland}/bin/hyprctl reload";
            }

            {
              label = "";
              command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
            }
            {
              label = "󰗽";
              command = "${pkgs.hyprland}/bin/hyprctl dispatch exit";
            }
            {
              label = "";
              command = "${systemctl} hibernate";
            }
            {
              label = "";
              command = "${systemctl} reboot --boot-loader-entry=auto-windows";
            }
            {
              label = "";
              command = "${systemctl} reboot";
            }
            {
              label = "";
              command = "${systemctl} poweroff";
            }
          ];
        };
      };

      style = with config.user-theme; ''
        @define-color bg ${bg};
        @define-color bg-alt ${bg-alt};
        @define-color fg ${fg};

        @define-color black ${black};
        @define-color blue ${blue};
        @define-color cyan ${cyan};
        @define-color red ${red};
        @define-color purple ${purple};

        @define-color noti-border-color rgba(255, 255, 255, 0.15);
        @define-color noti-bg rgb(17, 17, 27);
        @define-color noti-bg-hover rgb(27, 27, 43);
        @define-color noti-bg-focus rgba(27, 27, 27, 0.6);
        @define-color noti-close-bg rgba(255, 255, 255, 0.1);
        @define-color noti-close-bg-hover rgba(255, 255, 255, 0.15);
        @define-color text-color-disabled rgb(150, 150, 150);
        @define-color bg-selected rgb(0, 128, 255);

        * {
          font-family: Iosevka Custom, Symbols Nerd Font;
          font-weight: bold;
        }

        .control-center .notification-row:focus,
        .control-center .notification-row:hover {
          opacity: 1;
          background: @bg-alt;
        }

        .notification-row {
          outline: none;
          margin: 10px;
          padding: 0;
        }

        .notification {
          background: transparent;
          padding: 0;
          margin: 0px;
        }

        .notification-content {
          background: @bg;
          padding: 10px;
          border-radius: 5px;
          border: 2px solid #34548a;
          margin: 0;
        }

        .notification-default-action {
          margin: 0;
          padding: 0;
          border-radius: 5px;
        }

        .close-button {
          background: @red;
          color: @bg;
          text-shadow: none;
          padding: 0;
          border-radius: 5px;
          margin-top: 5px;
          margin-right: 5px;
        }

        .close-button:hover {
          box-shadow: none;
          background: @red;
          transition: all 0.15s ease-in-out;
          border: none;
        }

        .notification-action {
          border: 2px solid #34548a;
          border-top: none;
          border-radius: 5px;
        }

        .notification-default-action:hover,
        .notification-action:hover {
          color: @blue;
          background: @blue;
        }

        .notification-default-action {
          border-radius: 5px;
          margin: 0px;
        }

        .notification-default-action:not(:only-child) {
          border-bottom-left-radius: 7px;
          border-bottom-right-radius: 7px;
        }

        .notification-action:first-child {
          border-bottom-left-radius: 10px;
          background: @black;
        }

        .notification-action:last-child {
          border-bottom-right-radius: 10px;
          background: @black;
        }

        .inline-reply {
          margin-top: 8px;
        }

        .inline-reply-entry {
          background: @bg-alt;
          color: @fg;
          caret-color: @fg;
          border: 1px solid @noti-border-color;
          border-radius: 5px;
        }

        .inline-reply-button {
          margin-left: 4px;
          background: @noti-bg;
          border: 1px solid @noti-border-color;
          border-radius: 5px;
          color: @fg;
        }

        .inline-reply-button:disabled {
          background: initial;
          color: @text-color-disabled;
          border: 1px solid transparent;
        }

        .inline-reply-button:hover {
          background: @noti-bg-hover;
        }

        .body-image {
          margin-top: 6px;
          background-color: @fg;
          border-radius: 5px;
        }

        .summary {
          font-size: 16px;
          font-weight: 700;
          background: transparent;
          color: rgba(158, 206, 106, 1);
          text-shadow: none;
        }

        .time {
          font-size: 16px;
          font-weight: 700;
          background: transparent;
          color: @fg;
          text-shadow: none;
          margin-right: 18px;
        }

        .body {
          font-size: 15px;
          font-weight: 400;
          background: transparent;
          color: @fg;
          text-shadow: none;
        }

        .control-center {
          background: @bg;
          border: 2px solid @cyan;
          border-radius: 5px;
        }

        .control-center-list {
          background: transparent;
        }

        .control-center-list-placeholder {
          opacity: 0.5;
        }

        .floating-notifications {
          background: transparent;
        }

        .blank-window {
          background: alpha(black, 0.1);
        }

        .widget-title {
          color: @purple;
          background: @bg-alt;
          padding: 5px 10px;
          margin: 10px 10px 5px 10px;
          font-size: 1.5rem;
          border-radius: 5px;
        }

        .widget-title > button {
          font-size: 1rem;
          color: @fg;
          text-shadow: none;
          background: @noti-bg;
          box-shadow: none;
          border-radius: 5px;
        }

        .widget-title > button:hover {
          background: @red;
          color: @bg;
        }

        .widget-dnd {
          background: @bg-alt;
          padding: 5px 10px;
          margin: 5px 10px 10px 10px;
          border-radius: 5px;
          font-size: large;
          color: @purple;
        }

        .widget-dnd > switch {
          background: @blue;
          /* border: 1px solid @blue; */
          border-radius: 5px;
        }

        .widget-dnd > switch:checked {
          background: @red;
          border: 1px solid @red;
        }

        .widget-dnd > switch slider {
          background: @bg;
          border-radius: 5px;
        }

        .widget-dnd > switch:checked slider {
          background: @bg;
          border-radius: 5px;
        }

        .widget-label {
          margin: 10px 10px 5px 10px;
        }

        .widget-label > label {
          font-size: 1rem;
          color: @fg;
        }

        .widget-mpris {
          color: @fg;
          background: transparent;
          padding: 5px;
          margin: 5px;
          border-radius: 5px;
        }

        .widget-mpris > box > button {
          border-radius: 5px;
        }

        .widget-mpris-player {
          padding: 5px;
          margin: 10px;
        }

        .widget-mpris-title {
          font-weight: 700;
          font-size: 1.25rem;
        }

        .widget-mpris-subtitle {
          font-size: 1.1rem;
        }

        .widget-buttons-grid {
          font-size: x-large;
          padding: 5px;
          margin: 5px 10px 10px 10px;
          border-radius: 5px;
          background: @bg-alt;
        }

        .widget-buttons-grid > flowbox > flowboxchild > button {
          font-weight: normal;
          margin: 3px;
          background: @bg;
          border-radius: 5px;
          color: @fg;
        }

        .widget-buttons-grid > flowbox > flowboxchild > button:hover {
          color: @purple;
        }

        .widget-menubar > box > .menu-button-bar > button {
          border: none;
          background: transparent;
        }

        .topbar-buttons > button {
          border: none;
          background: transparent;
        }

        /* .widget-inhibitors {
            margin: 8px;
            font-size: 1.5rem
        }

        .widget-inhibitors>button {
            font-size: initial;
            color: @fg;
            text-shadow: none;
            background: @noti-bg;
            border: 1px solid red;
            box-shadow: none;
            border-radius: 7px
        }

        .widget-inhibitors>button:hover {
            background: @noti-bg-hover
        } */
      '';
    };
  };
}
