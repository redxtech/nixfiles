{ pkgs, lib, config, ... }:

with lib; {
  home = {
    packages = with pkgs; [
      # js
      nodejs

      rust-bin.stable.latest.default # rust beta
      # (rust-bin.selectLatestNightlyWith (toolchain: toolchain.default))

      # python
      (python3.withPackages (ps: with ps; [ dbus-python pygobject3 requests ]))

      # other
      sqlite # for mcfly
    ];

    shellAliases = rec {
      # js
      npr = "npm run";
    };

    sessionVariables = { PNPM_HOME = "${config.xdg.dataHome}/pnpm"; };
  };
}

