{ pkgs, inputs, ... }:

{
  programs.firefox = {

    enable = true;
    profiles.default = {
      id = 0;
      name = "Default";
      extensions = [
        inputs.firefox-addons.packages.${pkgs.system}.ublock-origin
        inputs.firefox-addons.packages.${pkgs.system}.darkreader
        inputs.firefox-addons.packages.${pkgs.system}.privacy-badger
      ];
      search = {
        default = "DuckDuckGo";
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
