{ lib, config, ... }:

# https://wiki.nixos.org/wiki/Unbound
# https://mynixos.com/options/services.unbound
# https://unbound.docs.nlnetlabs.nl/en/latest/manpages/unbound.conf.html

let
  cfg = config.modules.services.unbound;
  dnsPort = 5335;
  settingsDefaults = {
    # Recommendations for Pi-Hole (with minor tweaks)
    # https://docs.pi-hole.net/guides/dns/unbound/#configure-unbound
    server = {
      # Logging
      logfile = "/var/log/unbound/unbound.log";
      verbosity = 0;
      log-time-ascii = true;
      # Local access
      interface = [ "127.0.0.1" ];
      access-control = [ "127.0.0.1 allow" ];
      port = dnsPort;
      # IPv4, no IPv6
      do-ip4 = true;
      do-ip6 = false;
      prefer-ip6 = false;
      # TCP and UDP
      do-udp = true;
      do-tcp = true;
      # Other
      harden-glue = true;
      harden-dnssec-stripped = true;
      use-caps-for-id = false;
      edns-buffer-size = 1232;
      prefetch = true;
      num-threads = 1;
      private-address = [
        "192.168.0.0/16"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "10.0.0.0/8"
        "fd00::/8"
        "fe80::/10"
        "192.0.2.0/24"
        "198.51.100.0/24"
        "203.0.113.0/24"
        "255.255.255.255/32"
        "2001:db8::/32"
      ];
    };
  };
in
{
  options = {
    modules.services.unbound = {
      enable = lib.mkEnableOption "unbound DNS resolver" // {
        description = "Enable unbound DNS resolver";
        default = false;
      };
      # When true, /etc/resolv.conf will be updated to point to 127.0.0.1
      resolveLocalQueries = lib.mkOption {
        description = "Resolve local queries";
        type = lib.types.bool;
        default = false;
      };
      settings = lib.mkOption {
        description = "Unbound settings";
        type = lib.types.attrsOf lib.types.anything;
        default = settingsDefaults;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.unbound = {
      # Create standard log location: /var/log/unbound/
      serviceConfig = {
        User = "unbound";
        Group = "unbound";
        LogsDirectory = "unbound";
        StateDirectoryMode = "0750";
      };
    };

    services.unbound = {
      enable = true;
      inherit (cfg) resolveLocalQueries;
      # Merge defaults with user settings
      # TODO - Consider updating, to remove duplicate settings
      settings =
        lib.mkMerge [
          settingsDefaults
          cfg.settings
        ];
    };

    networking.firewall.allowedUDPPorts = [ dnsPort ];
    networking.firewall.allowedTCPPorts = [ dnsPort ];
  };
}
