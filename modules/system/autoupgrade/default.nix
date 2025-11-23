{ lib, config, options, pkgs, ... }:

# System Upgrade
# https://mynixos.com/options/system.autoUpgrade

let
  cfg = config.modules.system.autoUpgrade;
  logfile = "/var/log/nixos-upgrade.log";
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
        default = "04:00";
      };
      randomizedDelaySec = lib.mkOption {
        description = "Set randomized delay in seconds";
        type = lib.types.str;
        # See also: https://www.freedesktop.org/software/systemd/man/systemd.time.html
        default = "600";
      };
      fixedRandomDelay = lib.mkOption {
        description = "Fixed random delay in seconds before upgrade";
        type = lib.types.bool;
        default = true;
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
    };
  };

  config = lib.mkIf cfg.enable {
    system.autoUpgrade = {
      enable = true;
      inherit (cfg) allowReboot;
      inherit (cfg) dates;
      inherit (cfg) randomizedDelaySec;
      inherit (cfg) fixedRandomDelay;
      inherit (cfg) flags;
      inherit (cfg) flake;
    };

    systemd.services.nixos-upgrade.serviceConfig = {
      # Setup log file, with start and end timestamps
      ExecStartPre = ''
        ${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/date --rfc-3339=seconds | ${pkgs.findutils}/bin/xargs -I{} ${pkgs.coreutils}/bin/echo "[{}] === Auto Upgrade started ===" >> ${logfile}'
      '';
      ExecStartPost = ''
        ${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/date --rfc-3339=seconds | ${pkgs.findutils}/bin/xargs -I{} ${pkgs.coreutils}/bin/echo "[{}] === Auto Upgrade finished ===" >> ${logfile}'
      '';
      StandardOutput = "append:${logfile}";
      StandardError = "inherit";
    };
  };
}
