{ config, self, lib, pkgs, ... }:

let inherit (self.inputs.tu.packages.${pkgs.system}) tu;
in {
  config = {
    environment.systemPackages = with pkgs;
      let
        defaultTmpfs = "/mnt/config/tmpfs";

        overlay-store = writeShellScriptBin "overlay-store" ''
          TMPDIR="''${1:-${defaultTmpfs}}"
          mount -t overlay -o lowerdir=/nix/store,upperdir=$TMPDIR/store,workdir=$TMPDIR/storew overlay /nix/store
        '';
        overlay-tmp = writeShellScriptBin "overlay-tmp" ''
          TMPDIR="''${1:-${defaultTmpfs}}"
          mount -t overlay -o lowerdir=/tmp,upperdir=$TMPDIR/tmp,workdir=$TMPDIR/tmpw overlay /tmp
        '';

        mkFs = host: self.nixosConfigurations.${host}.config.fileSystems;
        mkFsOpts = fs: lib.concatStringsSep "," fs.options;
        mkMnt = fs: mount: "mount ${fs.${mount}.device} /mnt${mount}";
        mkMntBtrfs = fs: mount:
          "mount -t btrfs -o ${mkFsOpts fs.${mount}} ${
            fs.${mount}.device
          } /mnt${mount}";

        mount-system-quasar = let fs = mkFs "quasar";
        in writeShellScriptBin "mount-system-quasar" ''
          # mount main system
          ${lib.concatStringsSep "\n"
          (map (mkMnt fs) [ "/" "/boot" "/config" ])}

          # fix for running out of space
          TMPDIR="/mnt/config/tmpfs"
          mount -t overlay -o lowerdir=/nix/store,upperdir=$TMPDIR/store,workdir=$TMPDIR/storew overlay /nix/store
          mount -t overlay -o lowerdir=/tmp,upperdir=$TMPDIR/tmp,workdir=$TMPDIR/tmpw overlay /tmp
        '';
        mount-system-bastion = let fs = mkFs "bastion";
        in writeShellApplication {
          name = "mount-system-bastion";
          runtimeInputs = [ pkgs.btrfs-progs ];
          text = ''
            # mount main system
            ${lib.concatStringsSep "\n"
            (map (mkMntBtrfs fs) [ "/" "/home" "/nix" ])}
            mount ${fs."/boot".device} /mnt/boot

            # fix for running out of space
            TMPDIR="/mnt/tmp/tmpfs"
            mount -t overlay -o lowerdir=/nix/store,upperdir=$TMPDIR/store,workdir=$TMPDIR/storew overlay /nix/store
            mount -t overlay -o lowerdir=/tmp,upperdir=$TMPDIR/tmp,workdir=$TMPDIR/tmpw overlay /tmp
          '';
        };
      in [
        # cli tools to have on the iso
        atool
        bat
        btop
        curl
        dua
        eza
        fd
        file
        fzf
        git
        htop
        jq
        lsb-release
        mpv
        neovim
        parted
        procps
        ps_mem
        ripgrep
        rsync
        tealdeer
        tmux
        tu
        wget
        zoxide

        # custom scripts
        overlay-store
        overlay-tmp
        mount-system-quasar
        mount-system-bastion

        # gui apps
        firefox-bin
        gparted
        google-chrome
        kitty
        nemo-with-extensions
        qdirstat
        vesktop

        # theme
        dracula-theme
        papirus-icon-theme
        vimix-icon-theme

        # system
        btrfs-progs
      ];

    # fonts are packages right ?
    fonts = {
      fontconfig = {
        enable = true;

        defaultFonts = {
          serif = [ "Noto Serif" ];
          sansSerif = [ "Noto Sans" ];
          monospace = [ "Iosevka Custom" ];
          emoji = [ "Noto Color Emoji" ];
        };
      };

      fontDir.enable = true;

      packages = with pkgs; [
        cantarell-fonts
        dank-mono
        iosevka
        iosevka-custom
        (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" "Noto" ]; })
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        noto-fonts-extra
      ];
    };
  };
}
