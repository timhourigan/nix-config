# ============================================================================
# Host 1 — Edge Router (CWT N18 Mini PC)
#
# Role / Data Plane: edge firewall, NAT, DHCP (Kea), and recursive DNS
# (Unbound) for the whole 192.168.99.0/24 LAN. This box owns the boundary
# between the internet and everything behind it; it is deliberately kept
# minimal (no Prometheus/Grafana/UniFi here — those live on Host 2, the
# Management Server).
#
# Interface mapping (*** ADJUST TO YOUR HARDWARE *** — run `ip link` on the
# box after boot):
#   wan = enp1s0   the RJ45 port your ISP modem/router plugs into
#   lan = enp2s0   the RJ45 port your LAN switch / management host plugs into
# Port mapping (physical → interface) on this board:
#   P1 = WAN (upstream modem/office network)   → DHCP client
#   P2 = mgmt host, P4 = first AP             → both LAN, bridged into br0
# Interface NAMES below are PLACEHOLDERS. Find the real ones with `ip link`
# + `ethtool -p <iface> 5` at first boot (§Network state in README.md), then
# set wan + lanPorts. Only those two values change.
# ============================================================================

{ lib, pkgs, ... }:

let
  wan = "enp1s0"; # P1 — WAN, ISP/office uplink (DHCP client, Phase 1 staging)
  lan = "br0"; # LAN bridge — carries P2 (mgmt) + P4 (first AP)
  # Physical LAN ports on this box. *** PLACEHOLDERS *** — see README §Network state.
  lanPorts = [ "enp2s0" "enp4s0" ]; # P2 = mgmt, P4 = AP
  gw = "192.168.99.1"; # the router's own LAN address
  lanNet = "192.168.99.0/24";

  # ── OPTIONAL internal DNS (hostnames for everything) ──────────────────
  # Flip `enable = true` when you're ready to iterate on the quirks. When on:
  #   · Unbound authoritatively answers <name>.<domain> for every host below
  #     (static local-data — there is NO automatic DHCP↔name sync).
  #   · Kea tells DHCP clients to search <domain>, so bare `<name>` resolves.
  #   · Hosts not listed keep working via normal recursive DNS.
  # Known quirks (expect to work them out):
  #   · DHCP clients get dynamic IPs — give stable ones a Kea reservation
  #     (or static IP) or their name won't match a fixed address.
  #   · `.lan` is common but non-standard; `home.arpa` is the RFC 8375
  #     reserved name. Pick one, then use it for every host.
  #   · Kea's `domain-search` option data is best-effort per RFC 3397; if a
  #     client ignores it, use the full `<name>.<domain>` form instead.
  internalDns = {
    enable = false; # ✗ OFF by default
    domain = "lan"; # or "home.arpa" — see quirks above
    hosts = {
      # "<name>" = "<ip>"   → answers <name>.<domain>
      router = gw;
      mgmt = "192.168.99.10";
      media = "192.168.99.20"; # example — set to the media VM's real IP
      # fitness = "192.168.99.x";
      # <add your own>
    };
  };

  # DHCP options handed to every client (routers + DNS are mandatory; the
  # search domain is opt-in with internal DNS).
  dhcpOptions = [
    { name = "routers"; data = gw; }
    { name = "domain-name-servers"; data = gw; }
  ] ++ lib.optionals internalDns.enable [
    { name = "domain-search"; data = ''"${internalDns.domain}"''; }
  ];
in
{
  imports = [ ./hardware-configuration.nix ];

  # ── Identity ─────────────────────────────────────────────────────────────
  system.stateVersion = "26.05";
  networking.hostName = "edge-router";

  # ── Network state ─────────────────────────────────────────────────────────
  # Scripted networking (NetworkManager deliberately *not* enabled — a router
  # wants deterministic, per-interface config, and NetworkManager would fight
  # Kea/Unbound over interface ownership).
  networking.useDHCP = false; # take control
  networking.interfaces.${wan}.useDHCP = true; # WAN: DHCP client
  # LAN: bridge the two LAN ports (P2 mgmt, P4 AP) into one segment.
  networking.bridges.${lan}.interfaces = lanPorts;
  networking.interfaces.${lan} = {
    useDHCP = false;
    ipv4.addresses = [{ address = gw; prefixLength = 24; }];
  };
  # (The default route comes from the WAN's DHCP lease.)

  # ── IPv4 forwarding + NAT (LAN → WAN masquerade) ─────────────────────────
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  networking.nat = {
    enable = true;
    externalInterface = wan;
    internalInterfaces = [ lan ];
  };

  # ── Firewall ─────────────────────────────────────────────────────────────
  # Trust the LAN wholesale. That single rule *is* the "open LAN ports for
  # Kea / Unbound / node_exporter" requirement — 67/udp, 53/tcp+udp and
  # 9100/tcp are all reachable from the LAN through it. The default policy
  # continues to drop unsolicited inbound traffic on the WAN interface.
  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [ lan ];

  # ── DHCP (Kea dhcp4) ─────────────────────────────────────────────────────
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [ lan ];
      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };
      # authoritative: we own this subnet, so answer immediately (no
      # DHCPDISCOVER delay).
      authoritative = true;
      valid-lifetime = 86400;
      subnet4 = [
        {
          id = 1;
          subnet = lanNet;
          pools = [{ pool = "192.168.99.50 - 192.168.99.200"; }];
          option-data = dhcpOptions;
        }
      ];
      loggers = [
        {
          name = "kea-dhcp4";
          output_options = [{ output = "stdout"; }];
        }
      ];
    };
  };

  # ── DNS (Unbound, recursive resolver) ───────────────────────────────────
  services.unbound.enable = true;
  services.unbound.settings.server = {
    # Bind to the LAN gateway so LAN clients can query, and to loopback so the
    # router itself (which points /etc/resolv.conf at 127.0.0.1) can resolve.
    interface = [ gw "127.0.0.1" ];
    access-control = [
      "127.0.0.0/8 allow"
      "${lanNet} allow"
    ];
    # Standard privacy / hardening for a stub-into-recursor box.
    hide-identity = true;
    hide-version = true;
    qname-minimisation = true;
    prefetch = true;
    aggressive-nsec = true;
  } // lib.optionalAttrs internalDns.enable {
    # Internal hostnames — authoritative static answers for <name>.<domain>.
    local-zone = [ ''"${internalDns.domain}." static'' ];
    local-data = map (n: ''"${n}.${internalDns.domain}. 3600 IN A ${internalDns.hosts.${n}}"'') (
      builtins.attrNames internalDns.hosts
    );
  };

  # ── Internal DNS — enable when ready ─────────────────────────────────────
  # (see the `internalDns` block at the top of this file + README §Internal
  # DNS). No other host config changes when you flip it on.

  # ── Telemetry (pulled by Host 2's Prometheus; nothing installed here) ────
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = gw;
    port = 9100;
    enabledCollectors = [ "systemd" ];
    openFirewall = false; # already reachable via the trusted LAN rule
  };

  # ── Management access (headless box — you need to get back in) ────────────
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
    };
    startWhenNeeded = true;
  };

  # ── User ─────────────────────────────────────────────────────────────────
  users.users.drn = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Set a real password on first login: `passwd`
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = [
      # dev machine (darrenmeehan@fedora)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5LOFpTvGdlomaMjY33qWhvybAVYJLZ9efU6wny2NUq hi@drn.ie"
      # ops (home-k8s, same key the app-node workflow uses)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHSmchQ7JS1UcyBy2lMoYuBQs/6H/VgqB+TrArRE6QDW home-k8s"
    ];
  };

  # ── Tooling for diagnosing on the box ─────────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    curl
    tcpdump
    mtr
    bind # provides `dig`, `host`
    ripgrep
  ];
}
