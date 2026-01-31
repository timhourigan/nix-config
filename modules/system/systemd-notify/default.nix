{ lib, config, pkgs, ... }:

let
  cfg = config.modules.system.systemd-notify;
  # Currently using pushover for notifications
  notificationService = "pushover";
in
{
  options = {
    modules.system.systemd-notify = {
      enable = lib.mkEnableOption "Notify on systemd failures" // {
        description = "Enable notification on systemd service failures";
        default = false;
      };
    };
    # Set a default onFailure for all services to notify pushover
    systemd.services = lib.mkOption {
      type = with lib.types; attrsOf (
        submodule {
          # %n is replaced with the service name
          config.onFailure = lib.mkIf cfg.enable [ "${notificationService}@%n.service" ];
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."${notificationService}@" = {
      description = "Notification service via ${notificationService} for %i";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.mkDefault ''
          ${pkgs.curl}/bin/curl -s -F "token=$NOTIFY_TOKEN" -F "user=$NOTIFY_USER" -F "title=Service Failure: %i" -F "message=The systemd service %i has failed on $(${pkgs.nettools}/bin/hostname)." https://api.pushover.net/1/messages.json
        '';
        EnvironmentFile = lib.mkDefault "/run/secrets/${notificationService}_env";
      };
    };
  };
}
