{
  config,
  pkgs,
  ...
}:

{
  cli.enable = true;

  desktop = {
    enable = true;

    apps = with pkgs; [
      insomnia # api client
      libreoffice # office suite
      multiviewer-for-f1 # formula 1 viewer
      piper # gui for ratbagd/logitech mouse control
      postman # api client
      prismlauncher # minecraft launcher
      via # keyboard flasher
      vscode-fhs # vs-code with fhs environment
    ];

    wm = {
      rules = [
        {
          class = "firefox-nightly";
          tile = true;
        }
        {
          class = "firefox-nightly";
          title = "Enter name of file to save to...";
          float = true;
        }
        {
          class = "firefox-nightly";
          title = ".*(Bitwarden Password Manager).*";
          float = true;
        }
        {
          title = "Picture.in.Picture";
          float = true;
          pin = true;
        }
        {
          title = "File Upload.*";
          float = true;
        }
        {
          class = "discord|vesktop|equibop";
          wsNum = 3;
          tile = true;
          follow = false;
        }
        {
          class = "thunderbird";
          ws = "files";
          follow = false;
        }
        {
          class = "thunderbird";
          title = "Write.*";
          float = true;
          ws = "*";
        }
        {
          class = "spotify";
          tile = true;
        }
        {
          class = "kitty";
          tile = true;
        }
        {
          class = "kitty_(btop|float)";
          float = true;
        }
        {
          class = "nemo|thunar";
          tile = true;
          opacity = "0.9 0.8";
        }
        {
          class = "Plex";
          ws = "video";
        }
        {
          class = "plexmediaplayer";
          ws = "video";
        }
        {
          class = "teams-for-linux";
          wsNum = 8;
          tile = true;
        }
        {
          class = "Element";
          ws = "chat";
          follow = false;
        }
        {
          class = "pavucontrol";
          float = true;
          maxSize = "1400 720";
        }
        {
          class = "Subl";
          ws = "*";
        }
        {
          class = "mpv";
          title = "Webcam";
          float = true;
        }
        {
          class = "gamescope";
          fullscreen = true;
        }
        {
          class = "org.prismlauncher.PrismLauncher";
          tile = true;
        }
        {
          class = "Minecraft*?(.*)";
          tile = true;
        }
        {
          class = ".qemu-system-x86_64-wrapped";
          wsNum = 4;
        }
      ]
      ++ (map
        (class: {
          inherit class;
          float = true;
        })
        [
          "dev.noctalia.noctalia-qs"
          "obsidian"
          "org.pulseaudio.pavucontrol"
          ".piper-wrapped"
          ".blueman-manager-wrapped"
        ]
      );
    };

    autostart = with pkgs; {
      desktop = [
        "equibop.desktop"
        "spotify.desktop"
      ];
      services = [
        (lib.getExe config.programs.noctalia-shell.package)
        "${thunar}/bin/thunar --daemon"
        "${wl-clipboard}/bin/wl-paste --type text  --watch cliphist store"
        "${wl-clipboard}/bin/wl-paste --type image --watch cliphist store"

        "${
          (writeShellApplication {
            name = "monitor_connection_fix";
            runtimeInputs = [
              coreutils
              socat
            ];
            text = ''
              handle() {
                case $1 in monitoradded*)
                  # loop through workspaces for each monitor and move them to where they should be
                  for ws in 1 2 3 4 5 6; do
                    hyprctl dispatch moveworkspacetomonitor $ws 0
                  done
                  for ws in 7 8 9 10; do
                    hyprctl dispatch moveworkspacetomonitor $ws 1
                  done
                esac
              }

              # listen on hyprland sock, send all results to the handle function
              socat - "UNIX-CONNECT:/tmp/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock" | while read -r line; do handle "$line"; done
            '';
          })
        }/bin/monitor_connection_fix"
      ];
      run = [ "${sftpman}/bin/sftpman mount_all" ];
      runDays = [ ];
    };
  };
}
