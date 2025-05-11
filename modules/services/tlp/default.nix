{ lib, config, options, ... }:

# tlp - Laptop battery management
# https://linrunner.de/tlp
# https://nixos.wiki/wiki/Laptop

let
  cfg = config.modules.services.tlp;
  # https://linrunner.de/tlp/settings
  defaultSettings = {
    # CPU
    # See options with `sudo tlp-stat -p`
    CPU_BOOST_ON_AC = 1;
    CPU_BOOST_ON_BAT = 0;
    CPU_SCALING_GOVERNOR_ON_AC = "performance";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
    # Battery
    # Start charging at 75%, stop charging at 85%
    START_CHARGE_THRESH_BAT0 = 75;
    STOP_CHARGE_THRESH_BAT0 = 85;
    RESTORE_THRESHOLDS_ON_BAT = 1;
    # Platform
    # See options with `sudo tlp-stat -p`
    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "low-power";
  };

in
{
  options = {
    modules.services.tlp = {
      enable = lib.mkEnableOption "tlp" // {
        description = "Enable tlp";
        default = false;
      };
      defaultSettings = lib.mkOption {
        description = "tlp settings";
        type = lib.types.attrs;
        default = defaultSettings;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.tlp = {
      enable = true;
      settings = cfg.defaultSettings;
    };
  };
}
