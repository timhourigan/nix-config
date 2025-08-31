{ config, ... }:

let
  homepageDashboard = import ../common/homepage-dashboard.nix { };
in
{
  # Modules
  modules = {
    services = {
      # caddy = {
      #   enable = true;
      #   configFile = config.sops.secrets."caddy".path;
      # };

      homepage-dashboard = {
        enable = true;
        environmentFile = config.sops.secrets."homepage_env".path;
        # Needs env var `HOMEPAGE_ALLOWED_HOSTS=localhost` to be set
        listenPort = 80;
        inherit (homepageDashboard) bookmarks;
        inherit (homepageDashboard) settings;
        inherit (homepageDashboard) services;
        inherit (homepageDashboard) widgets;
      };
    };
  };

  # Secrets
  sops = {
    secrets = {
      # caddy = {
      #   owner = "caddy";
      # };

      homepage_env = { };
    };
  };


}
