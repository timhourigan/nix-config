{ lib, config, ... }:

# Caddy Proxy
#
# When wanting to use a Caddyfile instead of services.caddy.virtualHosts."<host>"
#
# https://caddyserver.com/docs/
# https://nixos.wiki/wiki/Caddy
# https://search.nixos.org/options?query=services.caddy

let
  cfg = config.modules.services.caddy;
in
{
  options = {
    modules.services.caddy = {
      enable = lib.mkEnableOption "Caddy web server" // {
        description = "Enable the Caddy web server";
        default = false;
      };
      configFile = lib.mkOption {
        description = "Path to the Caddy configuration file (Caddyfile)";
        type = lib.types.path;
      };
      extraConfig = lib.mkOption {
        description = "Extra configuration to be passed to Caddy";
        type = lib.types.str;
        default = "";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.caddy = {
      enable = true;
      inherit (cfg) extraConfig;
      inherit (cfg) configFile;
    };

    # Start after network is up
    systemd.services.caddy.wantedBy = [ "multi-user.target" ];
  };
}
