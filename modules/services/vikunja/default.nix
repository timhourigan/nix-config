{ lib, config, options, ... }:

# https://vikunja.io/
# https://mynixos.com/nixpkgs/options/services.vikunja
#
# Using default SQLite database
#
# Config options:
# https://vikunja.io/docs/config-options/
#
# Command line:
# https://vikunja.io/docs/cli/
#
# To create a user:
# sudo vikunja user create --username <username> --email <email>

let
  cfg = config.modules.services.vikunja;
in
{
  options = {
    modules.services.vikunja = {
      enable = lib.mkEnableOption "Enable Vikunja" // {
        description = "Enable Vikunja service";
        default = false;
      };
      frontendScheme = lib.mkOption {
        type = lib.types.str;
        default = "http";
        description = "Scheme to use for the frontend (http or https)";
      };
      frontendHostname = lib.mkOption {
        type = lib.types.str;
        default = "vikunja.local";
        description = "Hostname to use for the frontend";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 3456;
        description = "Port for service";
      };
      settings = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional settings";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.vikunja = {
      enable = true;
      inherit (cfg) frontendScheme;
      inherit (cfg) frontendHostname;
      inherit (cfg) port;
      inherit (cfg) settings;
    };

    networking.firewall.allowedTCPPorts = [ config.services.vikunja.port ];
  };
}
