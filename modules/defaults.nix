{ lib, den, ... }:
{
  den.default.nixos.system.stateVersion = lib.mkDefault "25.11";
  den.default.homeManager.home.stateVersion = lib.mkDefault "25.11";

  den.default.includes = [
    den.provides.define-user
    den.provides.hostname
    den.provides.inputs'
    den.provides.self'

    # needed to propagate host settings to nixos and home-manager
    den.aspects.host-settings
  ];

  # enable hm by default
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # preserve user-to-host content without den's transition defaults
  den.schema.host.includes = [
    den.batteries.user-aspects
    den.batteries.mutual-provider
  ];
  den.migrations.user-host-content.acknowledged = true;
}
