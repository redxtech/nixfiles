# This file (and the global directory) holds config that i use on all hosts
{ inputs, outputs, pkgs, ... }: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    # ./acme.nix
    # ./auto-upgrade.nix
    ./cli.nix
    ./locale.nix
    ./nix.nix
    ./openssh.nix
    ./containers.nix
    ./sops.nix
    ./steam-hardware.nix
    # ./systemd-initrd.nix
    ./tailscale.nix
  ] ++ (builtins.attrValues outputs.nixosModules);

  home-manager.extraSpecialArgs = { inherit inputs outputs; };

  nixpkgs = {
    overlays = builtins.attrValues outputs.overlays;
    config = { allowUnfree = true; };
  };

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

  # passwordless sudo for ps_mem
  security.sudo = {
    enable = true;

    extraRules = [{
      commands = [{
        command = "${pkgs.ps_mem}/bin/ps_mem";
        options = [ "NOPASSWD" ];
      }];
      groups = [ "wheel" ];
    }];
  };

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
