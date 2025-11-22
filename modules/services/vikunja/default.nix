{ lib, config, options, ... }:

# https://vikunja.io/
# https://mynixos.com/nixpkgs/options/services.vikunja
#
# Using default SQLite database

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
        description = "Scheme to use for the Vikunja frontend (http or https)";
      };
      frontendHostname = lib.mkOption {
        type = lib.types.str;
        default = "vikunja.local";
        description = "Hostname to use for the Vikunja frontend";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.vikunja = {
      enable = true;
      inherit (cfg) frontendScheme;
      inherit (cfg) frontendHostname;
    };
  };
}
