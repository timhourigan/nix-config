{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.firefox;
in
{
  options = {
    modules.home.firefox = {
      enable = lib.mkEnableOption "Firefox" // {
        description = "Enable Firefox";
        default = false;
      };
      configPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        # TODO
        # There is a new default as of 26.05
        # Migration steps:
        #   rsync -avh ~/.mozilla/firefox/ ~/.config/mozilla/firefox/
        #   rm -rf ~/.mozilla/firefox
        # If MacOS, use Home Manager default
        # else (if Linux), use new default regardless of HM state version
        default = if pkgs.stdenv.isDarwin then null else ".mozilla/firefox"; # Old - Remove once migrated to new default of ${config.xdg.configHome}/mozilla/firefox
        #  else "${lib.removePrefix "${config.home.homeDirectory}/" config.xdg.configHome}/mozilla/firefox";
        description = "Path to the Firefox configuration directory, relative to the user's home directory. If null, uses the home-manager default.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      configPath = lib.mkIf (cfg.configPath != null) cfg.configPath;
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
  };
}
