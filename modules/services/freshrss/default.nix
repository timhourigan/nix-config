{ lib, config, options, ... }:

let
  cfg = config.modules.services.freshrss;
in
{
  options = {
    modules.services.freshrss = {
      enable = lib.mkEnableOption "FreshRSS" // {
        description = "Enable FreshRSS";
        default = false;
      };
      authType = lib.mkOption {
        description = "Authentication type (`form`, `http_auth`, `none`)";
        type = lib.types.str;
        default = "form";
      };
      baseUrl = lib.mkOption {
        description = "Default URL";
        type = lib.types.str;
        default = "http://freshrss.localhost";
      };
      webserver = lib.mkOption {
        description = "Webserver to use (e.g. `caddy`, `nginx`)";
        type = lib.types.str;
        default = "caddy";
      };
      virtualHost = lib.mkOption {
        description = "Virtual host to use";
        type = lib.types.str;
        default = "freshrss.localhost";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.freshrss = {
      enable = true;
      inherit (cfg) authType;
      inherit (cfg) baseUrl;
      inherit (cfg) webserver;
      inherit (cfg) virtualHost;
    };
  };
}
