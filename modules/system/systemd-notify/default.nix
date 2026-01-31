{ lib, config, pkgs, ... }:

let
  cfg = config.modules.system.systemd-notify;
  # Using pushover for notifications
  notificationService = "pushover";
  notificationURI = "https://api.pushover.net/1/messages.json";
in
{
  options = {
    modules.system.systemd-notify = {
      enable = lib.mkEnableOption "Notify on systemd failures" // {
        description = "Enable notification on systemd service failures";
        default = false;
      };
    };
    # Set a default onFailure for all services to notify
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
      # %i is replaced the failed service name
      description = "Notification service via ${notificationService} for %i";
      # Prevent recursive failures
      onFailure = lib.mkForce [ ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.mkDefault ''
          ${pkgs.curl}/bin/curl -s -F "token=$NOTIFY_TOKEN" -F "user=$NOTIFY_USER" -F "title=Service Failure: %i" -F "message=The systemd service %i has failed on $(${pkgs.nettools}/bin/hostname)." ${notificationURI}
        '';
        EnvironmentFile = lib.mkDefault "/run/secrets/${notificationService}_env";
      };
    };
  };
}
