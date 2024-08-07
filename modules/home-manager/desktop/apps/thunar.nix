{ config, lib, pkgs, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    xdg.configFile."Thunar/uca.xml".text = let
      term = "${pkgs.kitty}/bin/kitty";
      scripts = cfg.wm.scripts;
      clipCmd = if cfg.wm.wm == "bspwm" then
        "${pkgs.xclip}/bin/xclip -i selection c"
      else
        "${pkgs.wl-clipboard}/bin/wl-copy";
      mediainfoCmd =
        "${term} ${pkgs.fish}/bin/fish -c '${pkgs.mediainfo}/bin/mediainfo %F; read -n 1 -p \"echo Press any key to continue...\"'";
    in ''
      <?xml version="1.0" encoding="UTF-8"?>
      <actions>
        <action>
          <icon>utilities-terminal</icon>
          <name>Open terminal here</name>
          <submenu></submenu>
          <unique-id>1654248846109487-1</unique-id>
          <command>${term} --directory %f</command>
          <description>Opens a terminal in the selected directory.</description>
          <range></range>
          <patterns>*</patterns>
          <startup-notify/>
          <directories/>
        </action>
        <action>
          <icon>utilities-terminal</icon>
          <name>Open terminal here</name>
          <submenu></submenu>
          <unique-id>1654595233060299-2</unique-id>
          <command>${term} --directory %d</command>
          <description>Opens a terminal in the current directory.</description>
          <range></range>
          <patterns>*</patterns>
          <audio-files/>
          <image-files/>
          <other-files/>
          <text-files/>
          <video-files/>
        </action>
        <action>
          <icon>folder-adwaita-script</icon>
          <name>Open folder as root</name>
          <submenu></submenu>
          <unique-id>1654600062096257-1</unique-id>
          <command>${pkgs.polkit}/bin/pkexec ${pkgs.thunar}/bin/thunar %f</command>
          <description>Opens the folder with root privileges.</description>
          <range></range>
          <patterns>*</patterns>
          <directories/>
        </action>
        <action>
          <icon>clipboard</icon>
          <name>Copy contents</name>
          <submenu></submenu>
          <unique-id>1654595051238529-1</unique-id>
          <command>cat %F | ${clipCmd}</command>
          <description>Copies the contents of selected files to clipboard.</description>
          <range></range>
          <patterns>*</patterns>
          <image-files/>
          <other-files/>
          <text-files/>
        </action>
        <action>
          <icon>video-x-generic</icon>
          <name>Encode video...</name>
          <submenu></submenu>
          <unique-id>1654603048016562-1</unique-id>
          <command>${scripts.rofi.encoder} %n</command>
          <description>Encode a video with selectable options.</description>
          <range></range>
          <patterns>*</patterns>
          <video-files/>
        </action>
        <action>
          <icon>archive</icon>
          <name>Create archive...</name>
          <submenu></submenu>
          <unique-id>1654596275298475-5</unique-id>
          <command>${scripts.rofi.archiver} %N</command>
          <description>Compresses files with atool.</description>
          <range></range>
          <patterns>*</patterns>
          <directories/>
          <audio-files/>
          <image-files/>
          <other-files/>
          <text-files/>
          <video-files/>
        </action>
        <action>
          <icon>cm_extractfiles</icon>
          <name>Unpack archive...</name>
          <submenu></submenu>
          <unique-id>1654596052635533-4</unique-id>
          <command>${scripts.general.unarchiver} %n</command>
          <description>Uses atool to unpack the selected files.</description>
          <range></range>
          <patterns>*.gz;*.tgz;*.bz;*.tbz;*.bz2;*.tbz2;*.Z;*.tZ;*.lzo;*.tzo;*.lz;*.tlz;*.xz;*.txz;*.7z;*.t7z;*.tar;*.zip;*.jar;*.war;*.rar;*.lha;*.lhz;*.alz;*.ace;*.a;*.;*.arj;*.arc;*.rpm;*.deb;*.cab;*.lzma;*.rz;*.lrz;*.cpio</patterns>
          <other-files/>
        </action>
        <action>
          <icon>edit-select-text</icon>
          <name>Rename to lower case</name>
          <submenu></submenu>
          <unique-id>1654595577242192-3</unique-id>
          <command>for file in %N; do mv &quot;$file&quot; &quot;$(echo &quot;$file&quot; | tr &apos;[:upper:]&apos; &apos;[:lower:]&apos;)&quot;; done</command>
          <description>Rename all selected files to lower case.</description>
          <range></range>
          <patterns>*</patterns>
        </action>
        <action>
          <icon>tartube-info-tray</icon>
          <name>Show Mediainfo</name>
          <submenu></submenu>
          <unique-id>1679196871442600-1</unique-id>
          <command>${mediainfoCmd}</command>
          <description>Shows the mediainfo output for the selected file</description>
          <range>*</range>
          <patterns>*</patterns>
          <video-files/>
        </action>
      </actions>
    '';
  };
}
