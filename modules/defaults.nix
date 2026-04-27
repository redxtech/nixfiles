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

  # host<->user provides
  den.ctx.user.includes = [ den._.mutual-provider ];
}
