{ lib, config, options, ... }:

let
  cfg = config.modules.services.gc;
in
{
  options = {
    modules.services.gc = {
      enable = lib.mkEnableOption "Garbage collection" // {
        description = "Enable garbage collection";
        default = false;
      };
      persistent = lib.mkOption {
        description = "Enable persistent timer";
        type = lib.types.bool;
        default = true;
      };
      dates = lib.mkOption {
        description = "Set the dates/cron for garbage collection";
        type = lib.types.str;
        default = "weekly";
      };
      options = lib.mkOption {
        description = "Set the options for garbage collection";
        type = lib.types.str;
        default = "--delete-older-than 30d";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nix.gc = {
      automatic = true;
      persistent = cfg.persistent;
      dates = cfg.dates;
      options = cfg.options;
    };
  };
}
