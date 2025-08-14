{ lib, config, options, ... }:

# Homepage Dashboard
# https://gethomepage.dev
# https://mynixos.com/nixpkgs/options/services.homepage-dashboard

let
  cfg = config.modules.services.homepage-dashboard;
in
{
  options = {
    modules.services.homepage-dashboard = {
      enable = lib.mkEnableOption "Homepage Dashboard" // {
        description = "Enable the Homepage Dashboard";
        default = false;
      };
      allowedHosts = lib.mkOption {
        type = lib.types.str;
        default = "localhost:8082,127.0.0.1:8082";
        description = "Allowed hosts (Will be overridden by environment file)";
      };
      bookmarks = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "Bookmarks configuration";
      };
      environmentFile = lib.mkOption {
        type = lib.types.path;
        description = "Path to the environment file";
      };
      listenPort = lib.mkOption {
        type = lib.types.port;
        default = 8082;
        description = "Port to bind to";
      };
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Open the firewall";
      };
      services = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "Services configuration";
      };
      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Settings configuration";
      };
      widgets = lib.mkOption {
        type = lib.types.listOf lib.types.attrs;
        default = [ ];
        description = "Widgets configuration";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      inherit (cfg) allowedHosts;
      inherit (cfg) bookmarks;
      inherit (cfg) environmentFile;
      inherit (cfg) listenPort;
      inherit (cfg) openFirewall;
      inherit (cfg) services;
      inherit (cfg) settings;
      inherit (cfg) widgets;
    };

    systemd.services.homepage-dashboard.serviceConfig =
      if cfg.listenPort < 1024 then {
        # WORKAROUND: Allow ports below 1024
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = lib.mkForce [ "CAP_NET_BIND_SERVICE" ];
        PrivateUsers = lib.mkForce false;
      }
      else
        { };
  };
}
