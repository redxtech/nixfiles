{ config, lib, pkgs, ... }:

let cfg = config.base;
in {
  options.base = { enable = lib.mkEnableOption "Enable base module"; };

  config = lib.mkIf cfg.enable {
    # some default home settings
    home = {
      username = lib.mkDefault "gabe";
      homeDirectory = lib.mkDefault "/home/${config.home.username}";
      stateVersion = lib.mkDefault "23.11";
      sessionPath = [ "$HOME/.local/bin" ];
      sessionVariables = { FLAKE = "$HOME/Code/nixfiles"; };
      language.base = "en_CA.UTF-8";
    };

    # some default programs
    programs.home-manager.enable = true;
    programs.git.enable = true;

    services.udiskie = {
      enable = false;

      settings = {
        program_options.terminal = "${pkgs.kitty}/bin/kitty --directory";
      };
    };

    # use sd-switch to handle service (re)start after change
    systemd.user.startServices = "sd-switch";

    # enable man pages
    manual = {
      html.enable = true;
      json.enable = lib.mkDefault true;
    };
  };
}
