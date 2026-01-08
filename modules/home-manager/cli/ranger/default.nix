{ config, lib, pkgs, ... }:

let cfg = config.cli;
in {
  imports = [ ./plugins.nix ./rifle.nix ];

  config = lib.mkIf cfg.enable {
    programs.ranger = {
      enable = true;

      extraPackages = with pkgs; [
        atool
        ffmpeg
        ffmpegthumbnailer
        highlight
        mediainfo
        p7zip
        rclone
        w3m
      ];

      extraConfig = ''
        default_linemode devicons2
      '';

      mappings = {
        # fzf
        f = "console fzf_filter%space";
        # zoxide
        # cz = "console z%space";
        cz = "zi";
        # archive
        ex = "extract";
        ec = "compress";
      };

      settings = {
        # colorscheme = "dracula";

        viewmode = "miller";
        column_ratios = "1,2,2";
        dirname_in_tabs = true;
        draw_borders = "both";
        hostname_in_titlebar = true;
        tilde_in_titlebar = true;

        autoupdate_cumulative_size = true;
        clear_filters_on_dir_change = true;
        idle_delay = 1000;
        max_history_size = 100;
        max_console_history_size = 100;
        metadata_deep_search = true;
        mouse_enabled = true;
        open_all_images = true;
        sort_case_insensitive = true;
        sort_directories_first = true;

        vcs_aware = true;
        vcs_backend_git = "enabled";
        vcs_backend_hg = "disabled";
        vcs_backend_bzr = "disabled";
        vcs_backend_svn = "disabled";

        preview_images = true;
        preview_images_method = "kitty"; # use sixel for foot
        preview_files = true;
        preview_directories = true;
        collapse_preview = true;
        use_preview_script = true;
        preview_script = "${config.xdg.configHome}/ranger/scope.sh";
      };
    };

    home.sessionVariables.RANGER_LOAD_DEFAULT_RC = "TRUE";

    xdg.configFile."ranger/colorschemes/dracula.py".source =
      let rev = "5bb840c5806252bf221fa180e9af0d2ffabe90bd";
      in pkgs.fetchurl {
        url =
          "https://raw.githubusercontent.com/dracula/ranger/${rev}/dracula.py";
        sha256 = "sha256-gqcwcC7T25bcboQkBWG6JZoqtVsQnGitaC1FNYXFjXg=";
      };

    xdg.configFile."ranger/scope.sh".source = let
      scope = pkgs.writeShellApplication {
        name = "scope.sh";
        runtimeInputs = with pkgs; [
          atool
          calibre
          catdoc
          coreutils
          epub-thumbnailer
          exiftool
          ffmpeg
          ffmpegthumbnailer
          fontforge
          gcc
          gnutar
          highlight
          imagemagick
          jq
          libarchive
          librsvg
          mediainfo
          mu
          p7zip
          pandoc
          poppler-utils
          python312Packages.pygments
          sqlite
          transmission_4
          unrar
          unzip
          w3m
        ];
        excludeShellChecks = [ "SC2034" ];
        text = builtins.readFile ./scope.sh;
      };
    in "${scope}/bin/scope.sh";

    xdg.desktopEntries."ranger" = {
      name = "ranger";
      genericName = "File Manager";
      comment = "Launches the ranger file manager";
      icon = "utilities-terminal";
      exec =
        "${config.programs.kitty.package}/bin/kitty ${config.programs.ranger.finalPackage}/bin/ranger %F";
      settings.TryExec = "ranger";
      settings.X-MultipleArgs = "false";
      terminal = false;
      type = "Application";
      startupNotify = true;
      categories = [ "System" "FileTools" "FileManager" ];
      mimeType = [ "inode/directory" ];
    };
  };
}
