{ pkgs, ... }:

{
  programs.firefox = {

    enable = true;
    profiles.default = {
      id = 0;
      name = "Default";
      extensions.packages = [
        pkgs.nur.repos.rycee.firefox-addons.consent-o-matic
        pkgs.nur.repos.rycee.firefox-addons.darkreader
        pkgs.nur.repos.rycee.firefox-addons.privacy-badger
        pkgs.nur.repos.rycee.firefox-addons.sponsorblock
        pkgs.nur.repos.rycee.firefox-addons.ublock-origin
      ];
      search = {
        default = "ddg";
        force = true;
        engines = {
          "NixOS Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@np" ];
          };
        };
      };
      settings = {
        # Homepage
        "browser.startup.homepage" = "duckduckgo.com";
        # HTTPS-Only Mode - Disabled
        # "dom.security.https_only_mode" = true;
        # "dom.security.https_only_mode_ever_enabled" = true;
        # Privacy settings
        # ... TBD
      };
    };
  };
}
