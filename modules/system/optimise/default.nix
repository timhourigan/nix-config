{ lib, config, ... }:

let
  cfg = config.modules.system.optimise;
in
{
  options = {
    modules.system.optimise = {
      enable = lib.mkEnableOption "Nix Store optimisation" // {
        description = "Enable Nix Store optimisation";
        default = false;
      };
      persistent = lib.mkOption {
        description = "Enable persistent timer";
        type = lib.types.bool;
        default = true;
      };
      dates = lib.mkOption {
        description = "Set the dates/cron for optimisation";
        type = lib.types.listOf lib.types.str;
        # See also: https://www.freedesktop.org/software/systemd/man/systemd.time.html
        default = [ "06:00" ];
      };
      randomizedDelaySec = lib.mkOption {
        description = "Set randomized delay in seconds";
        type = lib.types.str;
        # See also: https://www.freedesktop.org/software/systemd/man/systemd.time.html
        default = "600";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nix.optimise = {
      automatic = true;
      inherit (cfg) persistent;
      inherit (cfg) dates;
      inherit (cfg) randomizedDelaySec;
    };
  };
}
