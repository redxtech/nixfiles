{ lib, ... }:

{
  den.aspects.file-browser = {
    settings.enableThunar = lib.mkEnableOption "Whether to enable Thunar";

    # TODO: re-add custom actions when scripts are available
    homeManager =
      {
        host,
        config,
        pkgs,
        lib,
        ...
      }:
      lib.mkMerge (
        let
          term = lib.getExe' pkgs.foot "footclient";
          termFloat = "${term} --class footclient_float";
        in
        [
          # nemo config
          {
            home.packages = with pkgs; [
              nemo-with-extensions
              ffmpegthumbnailer # for video thumbnails
            ];

            xdg.dataFile =
              let
                scripts = config.scripts.scripts;
                wrapShell = command: "${lib.getExe pkgs.bash} -c '${command}'";

                # https://github.com/linuxmint/nemo/blob/master/files/usr/share/nemo/actions/sample.nemo_action
                actions = {
                  clamscan = {
                    name = "Clam Scan";
                    description = "Clam Scan";
                    exec = "${termFloat} ${lib.getExe pkgs.fish} -c '${lib.getExe' pkgs.clamav "clamscan"} %F; read -n 1 -p \"echo Press any key to continue...\"'";
                    icon = "bug-buddy";
                    selection = "Any";
                    extensions = "dir;exe;dll;zip;gz;7z;rar;";
                    mimetypes = null;
                    terminal = false;
                  };
                  convert = {
                    name = "Convert Image";
                    description = "Converts an image to another format with ImageMagick";
                    exec = "${lib.getExe scripts.convert-image} %F";
                    icon = "image";
                    selection = "s";
                    extensions = null;
                    mimetypes = "image/*";
                    terminal = false;
                  };
                  archive = {
                    name = "Create Archive";
                    description = "Creates an archive with atool";
                    exec = wrapShell "${lib.getExe scripts.archiver} %F";
                    icon = "archive";
                    selection = "notnone";
                    extensions = "any";
                    mimetypes = null;
                    terminal = false;
                  };
                  unpack = {
                    name = "Unpack Archive";
                    description = "Unpacks an archive with atool";
                    exec = "${lib.getExe scripts.unarchiver} %F";
                    icon = "archive-extract";
                    selection = "s";
                    extensions = "gz;tgz;bz;tbz;bz2;tbz2;Z;tZ;lzo;tzo;lz;tlz;xz;txz;7z;t7z;tar;zip;jar;war;rar;lha;lhz;alz;ace;a;arj;arc;rpm;deb;cab;lzma;rz;lrz;cpio";
                    mimetypes = null;
                    terminal = false;
                  };
                  encode = {
                    name = "Encode Video";
                    description = "Encodes a video with ffmpeg";
                    exec = "${lib.getExe scripts.encoder} %F";
                    icon = "video";
                    selection = "s";
                    extensions = null;
                    mimetypes = "video/*";
                    terminal = false;
                  };
                  mediainfo = {
                    name = "Show Mediainfo";
                    description = "Shows a file's mediainfo";
                    exec = "${lib.getExe pkgs.fish} -c '${lib.getExe pkgs.mediainfo} %F; read -n 1 -p \"echo Press any key to continue...\"'";
                    icon = "media-video";
                    selection = "s";
                    extensions = null;
                    mimetypes = "video/*;audio/*";
                    terminal = true;
                  };
                };
                mkAction = name: action: ''
                  [Nemo Action]
                  Name=${action.name}
                  Comment=${action.description}
                  Icon-Name=${action.icon}

                  Exec=${action.exec}
                  ${if action.terminal then "Terminal=true" else "Terminal=false"}

                  Selection=${action.selection}
                  ${if action.extensions != null then "Extensions=${action.extensions}" else ""}${
                    if action.mimetypes != null then "Mimetypes=${action.mimetypes}" else ""
                  }'';
              in
              builtins.listToAttrs (
                lib.mapAttrsToList (name: action: {
                  name = "nemo/actions/${name}.nemo_action";
                  value.text = mkAction name action;
                }) actions
              );

            dconf.settings =
              let
                foot = {
                  exec = "${pkgs.foot}/bin/footclient";
                  exec-arg = "";
                };
              in
              {
                "org/nemo/desktop".show-desktop-icons = false;
                "org/cinnamon/desktop/default-applications/terminal" = foot;
                "org/gnome/desktop/default-applications/terminal" = foot;
                "org/cinnamon/desktop/applications/terminal" = foot;
                "org/gnome/desktop/applications/terminal" = foot;
              };
          }

          # thunar config
          (lib.mkIf host.settings.file-browser.enableThunar (
            let
              thunar-with-meta = pkgs.thunar.overrideAttrs (prev: {
                meta.mainProgram = "thunar";
              });
              thunar-with-plugins = thunar-with-meta.override {
                thunarPlugins = with pkgs; [
                  thunar-archive-plugin
                  thunar-vcs-plugin
                  thunar-volman
                ];
              };
            in
            {
              home.packages = [
                thunar-with-plugins
                pkgs.ffmpegthumbnailer # for video thumbnails
              ];

              xdg.configFile."Thunar/uca.xml".text =
                let
                  scripts = config.scripts.scripts;
                  mediainfoCmd = "${termFloat} ${lib.getExe pkgs.fish} -c '${lib.getExe pkgs.mediainfo} %F; read -n 1 -p \"echo Press any key to continue...\"'";

                  mkAction =
                    {
                      name,
                      icon,
                      id,
                      command,
                      description,
                      range ? "",
                      patterns ? "*",
                      append ? [ ],
                    }:
                    let
                      appended = lib.concatStringsSep "\n" (map (str: "<${str}/>") append);
                    in
                    ''
                      <action>
                        <name>${name}</name>
                        <icon>${icon}</icon>
                        <submenu></submenu>
                        <unique-id>${id}</unique-id>
                        <command>${command}</command>
                        <description>${description}</description>
                        <range>${range}</range>
                        <patterns>${patterns}</patterns>
                        ${appended}
                      </action>
                    '';

                  actions = map mkAction [
                    {
                      name = "Open terminal here";
                      icon = "utilities-terminal";
                      id = "1654248846109487-1";
                      command = "${term} --working-directory %f";
                      description = "Opens a terminal in the selected directory.";
                      append = [
                        "startup-notify"
                        "directories"
                      ];
                    }
                    {
                      name = "Open terminal here";
                      icon = "utilities-terminal";
                      id = "1654595233060299-2";
                      command = "${term} --working-directory %d";
                      description = "Opens a terminal in the selected directory.";
                      append = [
                        "audio-files"
                        "image-files"
                        "other-files"
                        "text-files"
                        "video-files"
                      ];
                    }
                    # TODO: fix this issue (pkexec must be setuid root)
                    {
                      name = "Open folder as root";
                      icon = "folder-adwaita-script";
                      id = "1654600062096257-1";
                      command = "${pkgs.polkit}/bin/pkexec ${lib.getExe thunar-with-plugins} %f";
                      description = "Opens the folder with root privileges.";
                      append = [ "directories" ];
                    }
                    {
                      name = "Copy contents";
                      icon = "clipboard";
                      id = "1654595051238529-1";
                      command = "cat %F | ${pkgs.wl-clipboard}/bin/wl-copy";
                      description = "Copies the contents of selected files to clipboard.";
                      append = [
                        "image-files"
                        "text-files"
                        "other-files"
                      ];
                    }
                    {
                      name = "Encode video...";
                      icon = "video-x-generic";
                      id = "1654603048016562-1";
                      command = "${lib.getExe scripts.encoder} %n";
                      description = "Encode a video with selectable options.";
                      append = [ "video-files" ];
                    }
                    {
                      name = "Create archive...";
                      icon = "archive";
                      id = "1654596275298475-5";
                      command = "${lib.getExe scripts.archiver} %N";
                      description = "Compresses files with atool.";
                      append = [
                        "directories"
                        "audio-files"
                        "image-files"
                        "other-files"
                        "text-files"
                        "video-files"
                      ];
                    }
                    {
                      name = "Unpack archive...";
                      icon = "cm_extractfiles";
                      id = "1654596052635533-4";
                      command = "${lib.getExe scripts.unarchiver} %n";
                      description = "Uses atool to unpack the selected files.";
                      patterns = "*.gz;*.tgz;*.bz;*.tbz;*.bz2;*.tbz2;*.Z;*.tZ;*.lzo;*.tzo;*.lz;*.tlz;*.xz;*.txz;*.7z;*.t7z;*.tar;*.zip;*.jar;*.war;*.rar;*.lha;*.lhz;*.alz;*.ace;*.a;*.;*.arj;*.arc;*.rpm;*.deb;*.cab;*.lzma;*.rz;*.lrz;*.cpio";
                      append = [
                        "other-files"
                      ];
                    }

                    # TODO: fix this as well (not showing up on any files)
                    {
                      name = "Rename to lower case";
                      icon = "edit-select-text";
                      id = "1654595577242192-3";
                      command = "for file in %N; do mv &quot;$file&quot; &quot;$(echo &quot;$file&quot; | tr &apos;[:upper:]&apos; &apos;[:lower:]&apos;)&quot;; done";
                      description = "Rename all selected files to lower case.";
                    }
                    {
                      name = "Show Mediainfo";
                      icon = "tartube-info-tray";
                      id = "1679196871442600-1";
                      command = "${mediainfoCmd}";
                      description = "Shows the mediainfo output for the selected file";
                      range = "*";
                      append = [ "video-files" ];
                    }
                  ];
                in
                ''
                  <?xml version="1.0" encoding="UTF-8"?>
                  <actions>
                    ${lib.concatStringsSep "\n" actions}
                  </actions>
                '';

              # start thunar daemon at startup
              programs.niri.settings.spawn-at-startup = [
                {
                  argv = [
                    (lib.getExe thunar-with-plugins)
                    "--daemon"
                  ];
                }
              ];
            }
          ))
        ]
      );
  };
}
