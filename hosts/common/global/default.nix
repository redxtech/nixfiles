# This file (and the global directory) holds config that i use on all hosts
{ inputs, outputs, pkgs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    # ./auto-upgrade.nix
    ./cli.nix
    ./locale.nix
    ./openssh.nix
    ./sops.nix
    # ./systemd-initrd.nix
    ./tailscale.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  environment.systemPackages = with pkgs; [
    # basic tools
    curl
    file
    gcc
    git
    htop
    killall
    lsb-release
    man-pages
    man-pages-posix
    neovim
    ps_mem
    unrar
    unzip
    wget
    xclip
  ];

  # fix for qt6 plugins
  environment.profileRelativeSessionVariables = {
    QT_PLUGIN_PATH = [ "/lib/qt-6/plugins" ];
  };

  hardware.enableRedistributableFirmware = true;

  # increase open file limit for sudoers
  security.pam.loginLimits = [
    {
      domain = "@wheel";
      item = "nofile";
      type = "soft";
      value = "524288";
    }
    {
      domain = "@wheel";
      item = "nofile";
      type = "hard";
      value = "1048576";
    }
  ];
}
