{ writeShellApplication, coreutils, choose, curl, libnotify, mpv, urlencode
, yt-dlp, jq, fuzzel, rofiCmd ? "${fuzzel}/bin/fuzzel", ... }:

writeShellApplication {
  name = "youtube";
  runtimeInputs = [ choose coreutils curl libnotify jq mpv urlencode yt-dlp ];

  text = ''
    # rofi script to view or download youtube videos
    # usage: youtube <watch|download> <url>

    # rofi_cmd: wrapper around rofi to set prompt text and size
    rofi_cmd () {
      prompt="$1 "
      shift
      ${rofiCmd} --dmenu --prompt "$prompt" "$@"
    }

    # send notification
    notify_send() {
      title="$1"
      body="$2"
      shift 2

      status="$(notify-send "$title" "$body" \
        --icon download \
        --app-name "YT-DLP" \
        "$@")"

      echo "$status"
    }

    main() {
    	# dtermine the mode
    	mode="''${1:-stream}"

    	prompt="Stream YT"

    	if test "$mode" = "download"; then
    		prompt="Download YT"
    	fi

    	query="$(rofi_cmd "$prompt 󰄾")"

    	# turn the query into a url
    	YT_API_KEY="$(cat ~/.config/secrets/youtube.txt)"
    	query="$(printf "%s" "$query" | urlencode)"
    	urlstring="https://www.googleapis.com/youtube/v3/search?part=snippet&q=''${query}&type=video&maxResults=20&key=''${YT_API_KEY}"

    	# fetch and parse the result
    	search_selection="$(curl -s "$urlstring" |
    		jq -r '.items[] | "\(.snippet.channelTitle) => \(.snippet.title) => youtu.be/\(.id.videoId)"' |
    		rofi_cmd 'Choose Video 󰄾' --width 60)"

    	# selected result
    	search_result="$(echo "$search_selection" | awk '{print $NF}')"

    	# url of the youtube video
    	url="https://$search_result"

    	# grab the name of the video
    	selection_name="$(echo "$search_selection" | choose -f " => " 1)"

    	if test "$mode" = "download"; then
    		if test "$(pwd)" = "$HOME"; then
    			dl_path="$HOME/Videos/YT/%(uploader)s/%(upload_date>%Y-%m-%d)s - %(title)s (%(id)s).%(ext)s"
    		else
    			dl_path="[%(uploader)s] - %(upload_date>%Y-%m-%d)s - %(title)s (%(id)s).%(ext)s"
    		fi

    		yt-dlp \
    			--output "$dl_path" \
    			--audio-quality 0 \
    			--embed-sub \
    			--embed-thumbnail \
    			--embed-chapters \
    			--embed-info-json \
    			--sponsorblock-mark all \
    			"$url"

    		notify_send \
    			"YouTube video downloaded" \
    			"The YouTube video ($selection_name) has been downloaded."
    	else
    		mpv "$url"
    	fi
    }

    main "$@"
  '';
}
