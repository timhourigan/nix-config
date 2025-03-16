{ ... }:

# restic
# https://mynixos.com/nixpkgs/options/services.restic.backups.%3Cname%3E
# https://search.nixos.org/options?channel=24.11&show=services.restic.backups

# timerConfig
# https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html#Calendar%20Events

# Example to list files in latest snapshot
# sudo restic-gatus-local --repo /mnt/backup/gatus/ ls latest

{
  services.restic.backups = {
    gatus-local = {
      initialize = true;
      # /var/lib/gatus is a symbolic link to /var/lib/private/gatus
      # Restic doesn't follow symbolic links 
      # - https://restic.readthedocs.io/en/stable/040_backup.html#backing-up-special-items-and-metadata 
      paths = [ "/var/lib/private/gatus" ];
      repository = "/mnt/backup/gatus";
      passwordFile = "/etc/nixos/secrets/restic-gatus-local";
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "1800";
      };
      pruneOpts = [
        "--keep-hourly 24"
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 20"
      ];
    };

    hass-local = {
      initialize = true;
      paths = [ "/var/lib/hass" ];
      exclude = [ "/var/lib/hass/backups" ];
      repository = "/mnt/backup/hass";
      passwordFile = "/etc/nixos/secrets/restic-hass-local";
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "1800";
      };
      pruneOpts = [
        "--keep-hourly 24"
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 20"
      ];
    };

    slimserver-local = {
      initialize = true;
      paths = [ "/var/lib/slimserver" ];
      repository = "/mnt/backup/slimserver";
      passwordFile = "/etc/nixos/secrets/restic-slimserver-local";
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "1800";
      };
      pruneOpts = [
        "--keep-hourly 24"
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 20"
      ];
    };

    zigbee2mqtt-local = {
      initialize = true;
      paths = [ "/var/lib/zigbee2mqtt" ];
      repository = "/mnt/backup/zigbee2mqtt";
      passwordFile = "/etc/nixos/secrets/restic-zigbee2mqtt-local";
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
        RandomizedDelaySec = "1800";
      };
      pruneOpts = [
        "--keep-hourly 24"
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 20"
      ];
    };
  };
}
