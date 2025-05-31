_:

# restic
# https://mynixos.com/nixpkgs/options/services.restic.backups.%3Cname%3E
# https://search.nixos.org/options?channel=24.11&show=services.restic.backups

# timerConfig
# https://www.freedesktop.org/software/systemd/man/latest/systemd.time.html#Calendar%20Events

# Example to list files in latest snapshot
# sudo restic-pihole-local --repo /mnt/backup/pihole/ ls latest

{
  services.restic.backups = {
    pihole-local = {
      initialize = true;
      paths = [ "/var/lib/pihole" ];
      repository = "/mnt/backup/pihole";
      passwordFile = "/etc/nixos/secrets/restic-pihole-local";
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
