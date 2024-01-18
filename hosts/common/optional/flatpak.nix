{ pkgs, inputs, ... }:

{
  services.flatpak = {
    enable = true;

    # packages = [ ];

    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };

  environment.systemPackages = with pkgs; [ gnome.gnome-software ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal ];
    config = { common.default = "*"; };
  };
}
