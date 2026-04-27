{
  den.aspects.scripts.homeManager =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      config =
        let
          cfg = config.scripts;
          scripts = lib.mapAttrsToList (_: value: value) cfg.scripts;
        in
        lib.mkIf cfg.enable {
          home.packages = [ cfg.mainPicker ] ++ scripts;

          scripts.scripts = {
            # pick clipboard history with fuzzel
            clipboard-picker = pkgs.writeShellApplication {
              name = "clipboard-picker";
              runtimeInputs = with pkgs; [
                cfg.mainPicker
                wl-clipboard
                cliphist
              ];
              text = ''
                cliphist list | fuzzel --dmenu --with-nth=2 --prompt "copy > " --width 60 | cliphist decode | wl-copy
              '';
            };

            # convert image to another format
            convert-image = pkgs.writeShellApplication {
              name = "convert-image";
              runtimeInputs = with pkgs; [
                cfg.mainPicker
                imagemagick
                nemo-with-extensions
                libnotify
              ];
              text = builtins.readFile ./convert-image.sh;
            };

            # copy currently playing song url to clipboard without tracking params
            copy-spotify-url = pkgs.writeShellApplication {
              name = "copy-spotify-url";
              runtimeInputs = with pkgs; [
                coreutils
                wl-clipboard
                playerctl
                ripgrep
                choose
              ];
              text = ''
                main() {
                	local player="''${1:-spotify}"

                	playerctl --player="$player" metadata |
                		rg 'xesam:url' |
                		choose 2 |
                		tr -d '\n' |
                		wl-copy
                }

                main "$@"
              '';
            };

            # encode video
            encoder = pkgs.writeShellApplication {
              name = "encoder";
              runtimeInputs = with pkgs; [
                cfg.mainPicker
                coreutils
                ffmpeg_7
                libnotify
                nemo-with-extensions
              ];
              text = builtins.readFile ./encoder.sh;
            };

            # TODO: add home-assistant helper
            # ha-helper = pkgs.writeShellApplication { };

            # powermenu
            # TODO: move entirely to noctalia
            powermenu = pkgs.writeShellApplication {
              name = "powermenu";
              runtimeInputs = with pkgs; [
                cfg.mainPicker
                config.programs.niri.package
                config.programs.noctalia-shell.package
                coreutils
                systemd
                playerctl
              ];
              text = builtins.readFile ./powermenu.sh;
            };

            # run ps_mem in a floating window
            ps_mem_float = pkgs.writeShellApplication {
              name = "ps_mem_float";
              runtimeInputs = with pkgs; [
                config.programs.foot.package
                fish
                ps_mem
              ];
              text = ''
                footclient --app-id footclient_float fish -c 'sudo ps_mem; read -s -n 1 -p "echo Press any key to continue..."'
              '';
            };

            # search current theme for icons
            search-icons = pkgs.writeShellApplication {
              name = "search-icons";
              runtimeInputs = with pkgs; [
                coreutils
                findutils
                fd
                sd
                wl-clipboard
              ];
              text = ''
                main() {
                  search_term="$1"
                  shift

                  found_icons="$(fd ".*($search_term).*" "$@" -i ${pkgs.papirus-icon-theme}/share/icons/Papirus)"

                  [ -z "$found_icons" ] && echo "no matching icons found" && return 1

                  echo "$found_icons" |
                    xargs -L1 basename |
                    sd '\.svg$' "" |
                    fuzzel --dmenu --prompt "choose icon: " |
                    sd "\n" "" |
                    wl-copy
                }

                main "$@"
              '';
            };

            # get weather from wttr.in
            wttr = pkgs.writeShellApplication {
              name = "wttr";
              runtimeInputs = with pkgs; [
                config.programs.foot.package
                fish
                curl
              ];
              text = ''
                footclient --app-id footclient_float fish -c 'curl wttr.in; read -s -n 1 -p "echo Press any key to continue..."'
              '';
            };

            # watch or download youtube videos
            youtube = pkgs.writeShellApplication {
              name = "youtube-picker";
              runtimeInputs = with pkgs; [
                cfg.mainPicker
                config.programs.mpv.package
                config.programs.yt-dlp.package
                coreutils
                choose
                curl
                libnotify
                jq
                urlencode
              ];
              text = builtins.readFile ./youtube.sh;
            };

            # archive scripts
            archiver = pkgs.writeShellApplication {
              name = "archiver";
              runtimeInputs = with pkgs; [
                cfg.mainPicker
                coreutils
                atool
                libnotify
                nemo-with-extensions
              ];
              text = builtins.readFile ./archiver.sh;
            };

            unarchiver = pkgs.writeShellApplication {
              name = "unarchiver";
              runtimeInputs = with pkgs; [
                atool
                libnotify
                nemo-with-extensions
              ];
              text = builtins.readFile ./unarchiver.sh;
            };
          };
        };
    };
}
