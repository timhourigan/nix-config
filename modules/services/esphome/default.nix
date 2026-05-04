{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.esphome;
  port = 6052;
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
        description = "ESPHome package to use";
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
      inherit port;
    };
  };
}
