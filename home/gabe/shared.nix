{ config, lib, pkgs, stable, ... }:

let
  cfg = config.desktop.wm;
  inherit (cfg) scripts;
in {
  cli = {
    enable = true;
    packages = with pkgs;
      [
        audible-cli # interact with audible
      ];
  };

  desktop = {
    enable = true;

    apps = with pkgs; [
      jellyfin-media-player # jellyfin client
      libation # audible client
      libreoffice # office suite
      multiviewer-for-f1 # formula 1 viewer
      piper # gui for ratbagd/logitech mouse control
      postman # api client
      plexamp # plex audio player
      prismlauncher # minecraft launcher
      r2modman # mod manager
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
          class = "discord|vesktop";
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
      ] ++ (map (class: {
        inherit class;
        tile = true;
      }) [
        "ancify launcher.desktop.exe"
        "beekeeper-studio"
        "com.obsproject.Studio"
        "ente"
        "feh"
        "feishin"
        "foot(client)?"
        "google-chrome"
        "heroic"
        "qimgv"
        "net.lutris.Lutris"
        "mpv"
        "Minecraft\\*?\\s(\\d\\.?)+"
        "MQTT-Explorer"
        "neovide"
        "org.prismlauncher.PrismLauncher"
        "Postman"
        "steam"
        "tauonmb"
        "thunderbird"
        "\\.?virt-manager(-wrapped)?"
      ]);

      binds = with pkgs;
        let
          bin = lib.getExe;
          runFloat = window:
            "${bspwm}/bin/bspc rule -a ${window} -o state=floating; ";
          kittyRun = "${kitty}/bin/kitty --single-instance ";

          ff = "${config.programs.firefox.finalPackage}/bin/firefox-nightly";
        in [
          {
            description = "open terminal";
            cmd = "${kittyRun}";
            keys = [ "super + Return" ];
          }
          {
            description = "open floating terminal";
            cmd = "${runFloat "kitty"} ${kittyRun}";
            keys = [ "super + shift + Return" ];
          }
          {
            description = "open other terminals";
            cmd =
              "{${bin alacritty},${xfce.xfce4-terminal}/bin/xfce4-terminal}";
            keys = [ "super + {shift,ctrl} + Return" ];
          }
          {
            description = "open rofi app launcher";
            cmd = "${bin rofi} -show drun";
            keys = [ "super + space" ];
          }
          {
            description = "open rofi launchers";
            cmd = "${bin rofi} -show {run,drun,window,ssh}";
            keys = [ "super + {r,d,ctrl + d,shift + d}" ];
          }
          {
            description = "rofi powermenu";
            cmd = scripts.wm.powermenu;
            keys = [ "super + BackSpace" "super + shift + e" ];
          }
          {
            description = "restart sxhkd";
            cmd = "${procps}/bin/pkill -USR1 -x sxhkd";
            keys = [ "super + Escape" ];
          }
          # bspwm hotkeys
          {
            description = "quit/restart bspwm";
            cmd = "${bspwm}/bin/bspc {quit,wm -r}";
            keys = [ "super + alt + {q,r}" ];
          }
          {
            description = "close current window/kill all instances of app";
            cmd = "${bspwm}/bin/bspc node -{c,k}";
            keys = [ "super + {_,shift+ }q" ];
          }
          {
            description = "alternate between the tiled and monocle layout";
            cmd = "${bspwm}/bin/bspc desktop -l next";
            keys = [ "super + m" ];
          }
          # {
          #   description = "send the newest marked node to the newest preselected node";
          #   cmd = "${bspwm}/bin/bspc node newest.marked.local -n newest.!automatic.local";
          #   keys = [ "super + y" ];
          # }
          # {
          #   description = "swap the current node and the biggest window";
          #   cmd = "${bspwm}/bin/bspc node -s biggest.window";
          #   keys = [ "super + g" ];
          # }
          # state flags
          {
            description =
              "set the window mode to {tiled,pseudo_tiled,floating,fullscreen}";
            cmd =
              "${bspwm}/bin/bspc node -t {tiled,pseudo_tiled,floating,fullscreen}";
            keys = [ "super + {t,shift + t,s,f}" ];
          }
          {
            description =
              "toggle the node flag {locked,sticky,private,hidden,marked}";
            cmd =
              "${bspwm}/bin/bspc node -g {locked,sticky,private,hidden,marked}";
            keys = [ "super + {x,y,z,v,ctrl + m}" ];
          }
          {
            description = "unhide a window";
            cmd =
              "${bspwm}/bin/bspc node $(${bspwm}/bin/bspc query -N -n .hidden.local | ${coreutils}/bin/tail -n1) -g hidden=off";
            keys = [ "super + ctrl + shift + v" ];
          }
          # focus/swap
          {
            description = "open window switcher";
            cmd = "${bin rofi} -show window";
            keys = [ "alt + Tab" ];
          }
          {
            description =
              "{focus,move} the node in the {west,south,north,east} direction";
            cmd = "${bspwm}/bin/bspc node -{f,s} {west,south,north,east}";
            keys = [ "super + {_,shift + }{h,j,k,l}" ];
          }
          {
            description = "focus the {parent,brother,first,second} node";
            cmd = "${bspwm}/bin/bspc node -f @{parent,brother,first,second}";
            keys = [ "super + {p,b,comma,period}" ];
          }
          # {
          #   description =
          #     "focus the {next,previous} node in the current desktop";
          #   cmd = "${bspwm}/bin/bspc node -f {next,prev}.local.!hidden.window";
          #   keys = [ "super + {_,shift + }c" ];
          # }
          {
            description =
              "focus the {next,previous} desktop in the current monitor";
            cmd = "${bspwm}/bin/bspc desktop -f {prev,next}.local";
            keys = [ "super + bracket{left,right}" ];
          }
          {
            description = "focus the last {node,desktop}";
            cmd = "${bspwm}/bin/bspc {node,desktop} -f last";
            keys = [ "super + {grave,Tab}" ];
          }
          # {
          #   description = "focus the older or newer node in the focus history";
          #   cmd = "${bspwm}/bin/bspc wm -h off; ${bspwm}/bin/bspc node {older,newer} -f; ${bspwm}/bin/bspc wm -h on";
          #   keys = [ "super + {o,i}" ];
          # }
          {
            description = "{focus,send node to} desktop {1,2,3,4,5,6,7,8,9,10}";
            cmd = "${bspwm}/bin/bspc {desktop -f,node -d} '^{1-9,10}'";
            keys = [ "super + {_,shift + }{1-9,0}" ];
          }
          {
            description = "send to other monitor";
            cmd = "${bspwm}/bin/bspc node -m next";
            keys = [ "super + o" ];
          }
          # preselect
          {
            description = "preselect the direction {west,south,north,east}";
            cmd = "${bspwm}/bin/bspc node -p {west,south,north,east}";
            keys = [ "super + ctrl + {h,j,k,l}" ];
          }
          {
            description = "preselect the ratio {1-9}";
            cmd = "${bspwm}/bin/bspc node -o 0.{1-9}";
            keys = [ "super + ctrl + {1-9}" ];
          }
          {
            description = "cancel the preselection for the focused node";
            cmd = "${bspwm}/bin/bspc node -p cancel";
            keys = [ "super + ctrl + space" ];
          }
          {
            description = "cancel the preselection for the focused desktop";
            cmd =
              "${bspwm}/bin/bspc query -N -d | ${coreutils}/bin/xargs -I id -n 1 ${bspwm}/bin/bspc node id -p cancel";
            keys = [ "super + ctrl + shift + space" ];
          }
          # move/resize
          {
            description =
              "expand a window by moving one its {left,bottom,top,right} side outward";
            cmd =
              "${bspwm}/bin/bspc node -z {left -20 0,bottom 0 20,top 0 -20,right 20 0}";
            keys = [ "super + alt + {h,j,k,l}" ];
          }
          {
            description =
              "contract a window by moving its {left,bottom,top,right} side inward";
            cmd =
              "${bspwm}/bin/bspc node -z {right -20 0,top 0 20,bottom 0 -20,left 20 0}";
            keys = [ "super + alt + shift + {h,j,k,l}" ];
          }
          {
            description = "move a floating window {left,down,up,right}";
            cmd = "${bspwm}/bin/bspc node -v {-20 0,0 20,0 -20,20 0}";
            keys = [ "super + {Left,Down,Up,Right}" ];
          }
          # multimedia keys
          {
            description =
              "playerctl {play/pause,skip,prev} {spotify,firefox,mpv,general}";
            cmd = ''
              ${
                bin playerctl
              } --player={spotify,firefox,mopidy,mpv,""} {play-pause,next,previous}'';
            keys = [ "{_,shift,super,ctrl,alt} + XF86Audio{Play,Next,Prev}" ];
          }
          {
            description = "volume {up,down}";
            cmd = "${scripts.bar.pipewire} volume {up,down}";
            keys = [ "XF86Audio{Raise,Lower}Volume" ];
          }
          {
            description = "toggle mute";
            cmd = "${scripts.bar.pipewire} toggle-mute";
            keys = [ "XF86AudioMute" ];
          }
          # function keys
          {
            description = "brightness {up,down}";
            cmd = "${bin xorg.xbacklight} -{inc,dec} 5";
            keys = [ "XF86MonBrightness{Up,Down}" ];
          }
          {
            description = "screenshot {gui,screen (clipboard)}";
            cmd = "${bin flameshot} {gui,screen -c}";
            keys = [ "{_,shift} + Print" ];
          }
          # shortcut keys
          {
            description = "launch browser";
            cmd = ff;
            keys = [ "super + w" ];
          }
          {
            description = "open thunar";
            cmd = "thunar";
            keys = [ "super + g" ];
          }
          {
            description = "open neovide";
            cmd = "${neovide}/bin/neovide";
            keys = [ "super + n" ];
          }
          {
            description = "terminal exec {btop,ranger}";
            cmd = "${runFloat "kitty"} ${kittyRun} {${btop}/bin/btop,${
                bin ranger
              }}";
            keys = [ "super + shift + {m,r}" ];
          }
          # various miscellany
          {
            description = "{pop most recent,close all} notification";
            cmd = "${dunst}/bin/dunstctl {history-pop,close-all}";
            keys = [ "super + {shift,alt + }h" ];
          }
          {
            description = "copy & paste from clipboard history";
            cmd = scripts.general.clipboard;
            keys = [ "super + c" ];
          }
          # {
          #   description = "toggle {night,day} mode";
          #   cmd = "${bin redshift} -O {3500,6500}";
          #   keys = [ "super + bracket{down,up}" ];
          # }
          {
            description = "show keybind cheatsheet";
            cmd =
              "${rofi}/bin/rofi  -dmenu -i -p 'Hotkeys 󰄾' < ${config.xdg.dataHome}/sxhkd/cheatsheet | ${choose}/bin/choose -f ' => ' 2 | ${bash}/bin/bash";
            # cmd = "${bin sxhkhmenu} --opt-args=\"-dmenu -i -p Keybinds:\"";
            keys = [ "super + F1" ];
          }
        ];

      bspwm = {
        autostart = with pkgs; [
          "${config.home.homeDirectory}/.fehbg"
          "${xorg.xset}/bin/xset r rate 240 40" # keyboard repeat rate
          "${xorg.xset}/bin/xset s off -dpms" # disable screen blanking
          "${xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr"
        ];
      };
    };

    autostart = with pkgs; {
      desktop = [ "vesktop.desktop" "spotify.desktop" ];
      services = [
        "${thunar}/bin/thunar --daemon"
        "${pkgs.mako}/bin/mako"
        "${swww}/bin/swww-daemon"
        "${wl-clipboard}/bin/wl-paste --type text  --watch cliphist store"
        "${wl-clipboard}/bin/wl-paste --type image --watch cliphist store"

        "${
          (writeShellApplication {
            name = "monitor_connection_fix";
            runtimeInputs = [ coreutils socat ];
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

  services.snapcast.enable = false;
}
