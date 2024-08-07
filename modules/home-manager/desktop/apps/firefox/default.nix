{ config, pkgs, lib, ... }:

let cfg = config.programs.firefox;
in {
  options.programs.firefox.useCustomCss = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Whether to use custom CSS for Firefox.
    '';
  };

  config = {
    home = {
      sessionVariables = {
        BROWSER = "firefox-developer-edition -p gabe";
        FIREFOX = "firefox-developer-edition -p gabe";
      };
    };

    programs.firefox = {
      enable = true;

      package = pkgs.firefox-devedition-bin;

      profiles = {
        gabe = {
          settings = {
            "browser.aboutConfig.showWarning" = false;
            "browser.bookmarks.restore_default_bookmarks" = false;
            "browser.contentblocking.category" = "standard";
            "browser.link.open_newwindow" = 3;
            "browser.link.open_newwindow.restriction" = 2;
            "browser.link.open_newwindow.override.external" = 3;
            "browser.newtabpage.activity-stream.feeds.section.highlights" =
              true;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" =
              false;
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            # "browser.newtab.url" = "http://localhost:9009";
            "general.smoothScroll" = true;
            "browser.startup.homepage" = "http://localhost:9009";
            "browser.startup.page" = 3;
            "browser.toolbars.bookmarks.visibility" = "never";
            "browser.urlbar.update2.engineAliasRefresh" = true;
            "browser.warnOnQuitShortcut" = false;
            "devtools.inspector.activeSidebar" = "computedview";
            "devtools.inspector.selectedSidebar" = "computedview";
            "services.sync.prefs.sync-seen.browser.newtabpage.pinned" = true;
            "dom.forms.autocomplete.formautofill" = true;
            "full-screen-api.ignore-widgets" = false;
            "media.ffmpeg.vaapi.enabled" = true;
            "media.rdd-vpx.enabled" = true;
            "network.dns.disablePrefetch" = false;
            "network.predictor.enabled" = true;
            "network.prefetch-next" = true;
            "security.insecure_field_warning.contextual.enabled" = false;
            "svg.context-properties.content.enabled" = true;
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

            "browser.newtabpage.pinned" = [

              {
                url = "https://betaapp.fastmail.com/mail/Inbox";
                label = "fastmail";
              }
              {
                url = "https://www.youtube.com/";
                label = "yt";
              }
              {
                url = "https://github.com/redxtech";
                label = "github";
              }
              {
                url = "https://raindrop.io/";
                label = "raindrop";
              }
              {
                url = "https://dd.reddit.com/";
                label = "reddit";
              }
              {
                url = "https://news.ycombinator.com/news";
                label = "hn";
              }
              {
                url = "http://bastion:6060";
                label = "ollama";
              }
              {
                url = "https://chat.super.fish";
                label = "chat";
              }
              {
                url = "https://photos.google.com/";
                label = "photos";
              }
              { url = "https://hoppscotch.io/"; }
              { url = "https://gabedunn.dev/"; }
              {
                url = "https://monkeytype.com/";
                label = "monkeytype";
              }
            ];
          };

          userChrome =
            lib.mkIf cfg.useCustomCss (builtins.readFile ./userChrome.css);
          userContent =
            lib.mkIf cfg.useCustomCss (builtins.readFile ./userContent.css);

          # extensions = with inputs.firefox-addons.packages;
          # [
          # bitwarden
          # darkreader
          # enhancer-for-youtube
          # gesturefy
          # kagi-search
          # localcdn
          # raindropio
          # sidebery
          # sponsorblock
          # stylus
          # ublock-origin
          # ];

          search = {
            force = true;
            default = "Kagi";
            order = [
              "Kagi"
              "DuckDuckGo"
              "Google"
              "NixOS Wiki"
              "Nix Packages"
              "Nix Options"
              "Home Manager"
              "Arch Wiki"
              "Arch Packages"
              "AUR"
            ];
            engines = let updateInterval = 24 * 60 * 60 * 1000; # every day
            in {
              "Kagi" = {
                urls = [
                  { template = "https://kagi.com/search?q={searchTerms}"; }
                  {
                    template =
                      "https://kagi.com/api/autosuggest?q={searchTerms}";
                    type = "application/x-suggestions+json";
                  }
                ];
                iconUpdateURL = "https://assets.kagi.com/v2/favicon-32x32.png";
                updateInterval = updateInterval;
                definedAliases = [ "@kagi" "@k" ];
              };
              "NixOS Wiki" = {
                urls = [{
                  template =
                    "https://nixos.wiki/index.php?search={searchTerms}";
                }];
                iconUpdateURL = "https://nixos.wiki/favicon.png";
                updateInterval = updateInterval;
                definedAliases = [ "nw" ];
              };
              "Nix Packages" = {
                urls = [{
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }];
                icon =
                  "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "np" ];
              };
              "Nix Options" = {
                urls = [{
                  template = "https://search.nixos.org/options";
                  params = [
                    {
                      name = "type";
                      value = "packages";
                    }
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }];
                icon =
                  "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "no" ];
              };
              "Noogle" = {
                urls = [{
                  template = "https://noogle.dev/q";
                  params = [{
                    name = "term";
                    value = "{searchTerms}";
                  }];
                }];
                icon =
                  "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "nx" ];
              };
              "Home Manager" = {
                urls = [{
                  template =
                    "https://home-manager-options.extranix.com/?query={searchTerms}&release=master";
                }];
                iconUpdateURL =
                  "https://home-manager-options.extranix.com/home-manager-option-search/images/favicon.png";
                updateInterval = updateInterval;
                definedAliases = [ "hm" ];
              };
              "Arch Wiki" = {
                urls = [{
                  template =
                    "https://wiki.archlinux.org/index.php?search={searchTerms}";
                }];
                iconUpdateURL = "https://wiki.archlinux.org/favicon.ico";
                updateInterval = updateInterval;
                definedAliases = [ "aw" ];
              };
              "Arch Packages" = {
                urls = [{
                  template = "https://archlinux.org/packages/?q={searchTerms}";
                }];
                iconUpdateURL = "https://archlinux.org/static/favicon.ico";
                updateInterval = updateInterval;
                definedAliases = [ "ap" ];
              };
              "AUR" = {
                urls = [{
                  template =
                    "https://aur.archlinux.org/packages?O=0&K={searchTerms}";
                }];
                iconUpdateURL =
                  "https://aur.archlinux.org/static/images/favicon.ico";
                updateInterval = updateInterval;
                definedAliases = [ "aur" ];
              };
              "NPM" = {
                urls = [{
                  template = "https://www.npmjs.com/package/{searchTerms}";
                }];
                iconUpdateURL =
                  "https://static-production.npmjs.com/b0f1a8318363185cc2ea6a40ac23eeb2.png";
                updateInterval = updateInterval;
                definedAliases = [ "@npm" ];
              };
              "YouTube" = {
                urls = [{
                  template =
                    "https://www.youtube.com/results?search_query={searchTerms}";
                }];
                iconUpdateURL =
                  "https://www.youtube.com/s/desktop/85bdacdc/img/favicon_32x32.png";
                updateInterval = updateInterval;
                definedAliases = [ "yt" ];
              };
              "Amazon CA" = {
                urls =
                  [{ template = "https://www.amazon.ca/s?k={searchTerms}"; }];
                iconUpdateURL = "https://www.amazon.ca/favicon.ico";
                updateInterval = updateInterval;
                definedAliases = [ "@a" ];
              };
              "Bing".metaData.alias = "@b";
              "Google".metaData.alias = "@g";
              # "Amazon".metaData.alias = "@a";
            };
          };
        };
        other = {
          id = 1;
          name = "other";
          inherit (config.programs.firefox.profiles.gabe)
            settings userChrome userContent search;
        };
      };
    };

    xdg.desktopEntries."firefox-developer-edition" = let
      package = cfg.finalPackage;
      exe = lib.getExe package;
    in {
      name = "Firefox Developer Edition";
      genericName = "Web Browser";
      icon = "firefox-developer-edition";
      categories = [ "Network" "WebBrowser" ];

      exec = "${exe} --name firefox-aurora -p gabe %U";

      settings.TryExec = "firefox-developer-edition";
      settings.StartupWMClass = "firefox-aurora";
      startupNotify = true;
      type = "Application";

      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];

      actions = {
        "new-window" = {
          name = "New Window";
          exec = "${exe} -p gabe --new-window %U";
        };
        "new-private-window" = {
          name = "New Private Window";
          exec = "${exe} -p gabe --private-window %U";
        };
        "new-other-window" = {
          name = "New Other Window";
          exec = "${exe} -p other --private-window %U";
        };
        "profile-manager-window" = {
          name = "Profile Manager";
          exec = "${exe} --ProfileManager";
        };
      };
    };

    xdg.mimeApps.defaultApplications =
      let firefox = "firefox-developer-edition.desktop";

      in {
        "text/html" = [ firefox ];
        "text/xml" = [ firefox ];
        "x-scheme-handler/http" = [ firefox ];
        "x-scheme-handler/https" = [ firefox ];

        "x-scheme-handler/about" = [ firefox ];
        "x-scheme-handler/unknown" = [ firefox ];
        "x-scheme-handler/webcal" = [ firefox ];
      };
  };
}
