{ lib, config, options, ... }:

# Glances monitoring service
# https://github.com/nicolargo/glances

let
  cfg = config.modules.services.glances;
in
{
  options = {
    modules.services.glances = {
      enable = lib.mkEnableOption "glances" // {
        description = "Enable glances monitoring service";
        default = false;
      };
      webserver = lib.mkOption {
        description = "Enable webserver";
        type = lib.types.bool;
        default = true;
      };
      port = lib.mkOption {
        description = "Port";
        type = lib.types.int;
        default = 61208;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.glances = {
      enable = true;
      openFirewall = true;
      inherit (cfg) port;
      extraArgs = if cfg.webserver then [ "--webserver" ] else [ ];
    };
  };
}
