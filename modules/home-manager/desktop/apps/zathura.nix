{ config, lib, pkgs, ... }:

let cfg = config.desktop;
in {
  config = lib.mkIf cfg.enable {
    programs.zathura = {
      enable = true;

      extraConfig = ''
        set window-title-basename "true"
        set selection-clipboard "clipboard"

        # dracula color theme
        set notification-error-bg       rgba(255,85,85,1)     # Red
        set notification-error-fg       rgba(248,248,242,1)   # Foreground
        set notification-warning-bg     rgba(255,184,108,1)   # Orange
        set notification-warning-fg     rgba(68,71,90,1)      # Selection
        set notification-bg             rgba(40,42,54,1)      # Background
        set notification-fg             rgba(248,248,242,1)   # Foreground

        set completion-bg               rgba(40,42,54,1)      # Background
        set completion-fg               rgba(98,114,164,1)    # Comment
        set completion-group-bg         rgba(40,42,54,1)      # Background
        set completion-group-fg         rgba(98,114,164,1)    # Comment
        set completion-highlight-bg     rgba(68,71,90,1)      # Selection
        set completion-highlight-fg     rgba(248,248,242,1)   # Foreground

        set index-bg                    rgba(40,42,54,1)      # Background
        set index-fg                    rgba(248,248,242,1)   # Foreground
        set index-active-bg             rgba(68,71,90,1)      # Current Line
        set index-active-fg             rgba(248,248,242,1)   # Foreground

        set inputbar-bg                 rgba(40,42,54,1)      # Background
        set inputbar-fg                 rgba(248,248,242,1)   # Foreground
        set statusbar-bg                rgba(40,42,54,1)      # Background
        set statusbar-fg                rgba(248,248,242,1)   # Foreground

        set highlight-color             rgba(255,184,108,0.5) # Orange
        set highlight-active-color      rgba(255,121,198,0.5) # Pink

        set default-bg                  rgba(40,42,54,1)      # Background
        set default-fg                  rgba(248,248,242,1)   # Foreground

        set render-loading              true
        set render-loading-fg           rgba(40,42,54,1)      # Background
        set render-loading-bg           rgba(248,248,242,1)   # Foreground

        # recolor mode settings
        set recolor-lightcolor          rgba(40,42,54,1)      # Background
        set recolor-darkcolor           rgba(248,248,242,1)   # Foreground

        # startup options
        set adjust-open width
        set recolor true
      '';
    };
  };
}
