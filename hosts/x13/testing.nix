{ config, ... }:

let
  hpConfig = import ../common/homepage-dashboard.nix { };
  hpPort = 8082;
in
{
  # Modules
  modules = {
    services = {
      homepage-dashboard = {
        enable = false;
        environmentFile = config.sops.secrets."homepage_env".path;
        listenPort = hpPort;
        inherit (hpConfig) bookmarks;
        inherit (hpConfig) settings;
        inherit (hpConfig) services;
        inherit (hpConfig) widgets;
      };

      freshrss = {
        enable = false;
        authType = "none";
        webserver = "caddy";
        virtualHost = "freshrss.${config.custom.internalDomain}";
        baseUrl = "http://freshrss.${config.custom.internalDomain}";
      };

      vikunja = {
        enable = false;
      };
    };
  };

  # Caddy
  # Homepage
  # services.caddy.virtualHosts."${config.custom.internalDomain}" = {
  #   extraConfig = ''
  #     reverse_proxy http://${config.custom.internalDomain}:${toString hpPort}
  #   '';
  # };

  # Secrets
  sops = {
    secrets = {
      homepage_env = { };
    };
  };
}
