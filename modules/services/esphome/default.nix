{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.esphome;
in
{
  options = {
    modules.services.esphome = {
      enable = lib.mkEnableOption "Enable ESPHome" // {
        description = "Enable ESPHome dashboard service";
        default = false;
      };
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.esphome;
        description = "Package to use";
      };
      port = lib.mkOption {
        description = "Port for web interface";
        type = lib.types.port;
        default = 6052;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.esphome = {
      enable = true;
      inherit (cfg) package;
      usePing = true;
      openFirewall = true;
      # Listen on all interfaces, not just loopback
      address = "0.0.0.0";
      inherit (cfg) port;
    };
  };
}
