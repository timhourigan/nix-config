{ ... }:

# restic
# https://mynixos.com/nixpkgs/options/services.restic.backups.%3Cname%3E
# https://search.nixos.org/options?channel=24.11&show=services.restic.backups

# timerConfig
# https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html#Calendar%20Events

{
  services.restic.backups = {
    hass-local = {
      initialize = true;
      paths = [ "/var/lib/hass" ];
      exclude = [ "/var/lib/hass/backups" ];
      repository = "/mnt/backup/hass";
      passwordFile = "/etc/nixos/secrets/restic-hass-local";
      timerConfig = {
        OnCalendar = "hourly";
        Persistent = true;
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
