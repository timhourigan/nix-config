{ lib, config, options, ... }:

# System Upgrade
# https://mynixos.com/options/system.autoUpgrade

let
  cfg = config.modules.system.autoUpgrade;
in
{
  options = {
    modules.system.autoUpgrade = {
      enable = lib.mkEnableOption "Enable automatic upgrades" // {
        description = "Enable automatic upgrades of the system";
        default = false;
      };
      flake = lib.mkOption {
        description = "Flake to use for automatic upgrades";
        type = lib.types.str;
        default = "";
        example = "github:<repo-name>/nix-config";
      };
      dates = lib.mkOption {
        description = "Time/date for automatic upgrades (systemd timer format)";
        type = lib.types.str;
        default = "04:40";
      };
      allowReboot = lib.mkOption {
        description = "Allow automatic reboot after upgrade";
        type = lib.types.bool;
        default = false;
      };
      flags = lib.mkOption {
        description = "Flags for the upgrade command";
        type = lib.types.listOf lib.types.str;
        default = [
          # Don't update the lock file, use the version in git
          "--no-update-lock-file"
          # Refresh the repository
          "--refresh"
          # Print build logs / "--log-format bar-with-logs"
          "-L"
          "--verbose"
        ];
      };
      fixedRandomDelay = lib.mkOption {
        description = "Fixed random delay in seconds before upgrade";
        type = lib.types.bool;
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      inherit (cfg) allowReboot;
      inherit (cfg) dates;
      inherit (cfg) fixedRandomDelay;
      inherit (cfg) flags;
      inherit (cfg) flake;
    };

    systemd.services.nixos-upgrade.serviceConfig = {
      StandardOutput = "append:/var/log/nixos-upgrade.log";
      StandardError = "inherit";
    };
  };
}
