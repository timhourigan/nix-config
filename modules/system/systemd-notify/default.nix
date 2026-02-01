{ lib, config, pkgs, ... }:

let
  cfg = config.modules.system.systemd-notify;
  hostname = config.networking.hostName;
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
      description = "Notification service for ${notificationService} for %i";
      # Prevent recursive failures
      onFailure = lib.mkForce [ ];
      script = ''
        ${pkgs.curl}/bin/curl -s \
          --form-string "token=$NOTIFY_TOKEN" \
          --form-string "user=$NOTIFY_USER" \
          --form-string "title=${hostname} failure: $1" \
          --form-string "message=$1 has failed on ${hostname}" \
          ${notificationURI} \
          >> /var/log/${notificationService}-systemd-notify-$1.log 2>&1
      '';
      # %i translates to $1, the failed service name
      scriptArgs = "%i";
      serviceConfig = {
        Type = "oneshot";
        EnvironmentFile = lib.mkDefault config.sops.secrets."${notificationService}_systemd_env".path;
      };
    };
  };
}
