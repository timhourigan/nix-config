{ lib, config, options, ... }:

let
  cfg = config.modules.system.gc;
in
{
  options = {
    modules.system.gc = {
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
        # Use `systemd-analyze calendar weekly` to verify the syntax
        # See also: https://www.freedesktop.org/software/systemd/man/systemd.time.html
        default = "weekly";
      };
      randomizedDelaySec = lib.mkOption {
        description = "Set randomized delay in seconds";
        type = lib.types.str;
        # See also: https://www.freedesktop.org/software/systemd/man/systemd.time.html
        default = "600";
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
      inherit (cfg) persistent;
      inherit (cfg) dates;
      inherit (cfg) randomizedDelaySec;
      inherit (cfg) options;
    };
  };
}
