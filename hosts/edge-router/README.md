# edge-router — Data Plane (CWT N18 Mini PC)

Edge firewall, NAT (LAN→WAN), DHCP (Kea) and recursive DNS (Unbound) for the
`192.168.99.0/24` LAN. Deliberately minimal — **no** Prometheus/Grafana/UniFi
here; observability is scraped from this box by the Management plane
(`hosts/mgmt`).

| Plane | Host | IP | Runs |
| --- | --- | --- | --- |
| **Data** | `edge-router` | `192.168.99.1` (static) + WAN DHCP | NAT, Kea DHCP, Unbound DNS, node_exporter |
| **Management** | `mgmt` | `192.168.99.10` (static) | UniFi, Prometheus, Grafana |

## Network state

Physical ports → interfaces on this board (software-defined, see the `let`
block at the top of `hosts/edge-router/default.nix`):

| Port | Interface (placeholder) | Role | Config |
| --- | --- | --- | --- |
| **P1** | `enp1s0` (WAN) | ISP/office uplink | DHCP client (Phase 1 staging) |
| **P2** | `enp2s0` → `br0` (LAN) | mgmt host | bridged, static `192.168.99.1/24` |
| **P4** | `enp4s0` → `br0` (LAN) | first AP | bridged (same LAN as P2) |
| COM | serial console (DB9, not ethernet) | out-of-band | (see §Headless / serial) |

**P2 + P4 are bridged into `br0`** — any LAN port behaves like a switch port
on `192.168.99.0/24`; all LAN services (Kea, Unbound, NAT, firewall) key off
the bridge.

### Finding the real interface names (first boot)

The names in the table are **placeholders** — this board's 6-port NIC usually
enumerates as `enp1s0f0`…`enp1s0f5` (or `enpNsM` groupings), which rarely
line up 1:1 with the front-panel port labels. Do this **once, before
`nixos-install`**:

1. **Plug in the modem/office cable to P1 only**, and the mgmt host (or
   laptop) to P2.
2. Identify which physical port each interface name is, using carrier state
   and/or LED blink:

   ```sh
   ip link          # the port with a cable in it shows `state UP` / carrier
   # confirm by blinking an interface's port LED:
   ethtool -p enp1s0f1 5     # blinks enp1s0f1's physical port LED for 5s
   ```

   Repeat `ethtool -p <iface> 5` across `enp1s0f*` until you find the one
   wired to each cable → that maps `P1 → <wan iface>`, `P2 → <mgmt iface>`.
3. **Edit `hosts/edge-router/default.nix`** and set:

   ```nix
   wan = "<the P1 interface>";            # e.g. "enp1s0f0"
   lanPorts = [ "<P2 interface>" "<P4 interface>" ];   # e.g. [ "enp1s0f1" "enp1s0f3" ]
   ```

4. Rebuild on the box (or bake into the image before install):
   `nixos-rebuild switch --flake /etc/nixos#edge-router`

> **Only these two lines change.** The bridge (`br0`), static IP, NAT,
> firewall trust, Kea subnet and DNS all key off the `lan`/`gw`/`lanNet`
> values, which don't move.

## Build artifacts (run on your dev machine)

All three derive from the **same** `nixosConfigurations.edge-router`.

### 1. Bootable USB ISO (guided installer)

```sh
nix build .#edge-router-iso
ls result/*.iso                 # find the .iso
```

Write it to a USB stick:

```sh
sudo dd if=result/*.iso of=/dev/sdX bs=4M status=progress && sync
```

`/dev/sdX` = your USB stick (check with `lsblk` — **this wipes it**).

## Opening the boot menu (CWT N18 Mini PC)

This box was factory-loaded with **OPNsense**, so the disk boots first and the
USB installer only gets a shot if you interrupt with the boot menu:

1. Plug the USB into a **rear** port.
2. **Power on and immediately hammer F11** (this board's boot menu key —
   start pressing before the vendor logo, ~5×/sec for the first 3 s).
3. In the menu pick **“UEFI: <USB stick>”** (partition 1 if it appears twice).

If you land on a `boot:` prompt instead, you missed the window and it booted
OPNsense: type `boot` + Enter to run it anyway (nothing is broken), then
reboot and hit **F11 earlier**. Slow-pressers: use **Del** → **Boot override**
→ USB instead — no timing pressure.

**Snags:**

- **USB not listed** → re-flash the stick (`lsblk`; `sudo dd … && sync`), try
  another rear port, or confirm the ISO built (`ls result/`).
- **Secure Boot** refusing the unsigned ISO → BIOS **Security → Secure Boot →
  Disable**; if you want it back on later, re-enable after NixOS is installed.
- **Fast Boot** shortens the F11 window → disable it in BIOS **Boot** tab if
  you keep missing.
- OPNsense owns the disk: `nixos-install` repartitions `/dev/sda` and wipes it
  — export its config (System → Configuration → Backups) first if you need it.

## Installing to the internal SSD

1. Boot the USB installer (from §Build artifacts 1).
2. Log in as `drn` (password `changeme` — run `passwd` immediately).
3. Find your NIC names and **edit** `wan`/`lan` in
   `hosts/edge-router/default.nix` to match. Also fix the disk device in
   `hosts/edge-router/hardware-configuration.nix` if it isn't `/dev/sda`.
4. Get the config onto the installer (if you haven't baked it in):

   ```sh
   git clone https://github.com/<you>/nix-config /root/nix-config
   ```

5. Partition + format `/dev/sda` to match the config's `by-label` layout:

   ```sh
   parted /dev/sda -- mklabel gpt
   parted /dev/sda -- mkpart ESP fat32 1MiB 300MiB
   parted /dev/sda -- set 1 esp on
   parted /dev/sda -- mkpart NixOS ext4 300MiB 100%
   mkfs.fat -F32 -n boot /dev/sda1
   mkfs.ext4 -L nixos /dev/sda2
   ```

6. Mount and install:

   ```sh
   mount /dev/disk/by-label/nixos /mnt
   mkdir -p /mnt/boot && mount /dev/disk/by-label/boot /mnt/boot
   nixos-install --flake /root/nix-config#edge-router --no-root-passwd
   reboot
   ```

   (`--no-root-passwd` keeps the `changeme` `drn` user until you SSH in.)
7. On reboot the router is live: DHCP hands out `192.168.99.50-200`, DNS
   resolves through Unbound, NAT masquerades LAN→WAN.

> The `hardware-configuration.nix` here is a **generic placeholder** so the
> config builds everywhere (including for the ISO artifact above). On
> the real box, regenerate after install and commit it:
> `nixos-generate-config --root /mnt`, then copy the generated file into
> `hosts/edge-router/`.

## Ethernet cabling

```
ISP/office network ──(P1/WAN)──> [ edge-router ] ──(P2/LAN)──> mgmt (192.168.99.10)
                                        └──────(P4/LAN)──> UniFi AP (adopt via mgmt)
```

- **P1 (WAN)** connects to whatever is upstream — the ISP modem in place, or
  your existing router/office network when testing (the WAN is a DHCP client,
  so it works with either). For the final cutover put the ISP modem in bridge
  mode/disable its DHCP so the router is the only DHCP/DNS/NAT authority.
- **P2 (LAN, mgmt)** and **P4 (LAN, first AP)** are one bridged segment — any
  LAN client works on either port, no switch required until you add more.
- For a first bring-up without mgmt, plug your laptop into P2 or P4 and set a
  static `192.168.99.50/24` (Kea hands out `.50-.200`; `.1` is the router).

## Optional: internal hostnames for everything (internal DNS)

Unbound already resolves the internet. To also resolve **internal names**
(`media`, `mgmt`, … → their IPs) the router has an **opt-in** `internalDns`
block at the top of `hosts/edge-router/default.nix`:

```nix
internalDns = {
  enable = false;     # ← flip to true when ready
  domain = "lan";     # or "home.arpa" (RFC 8375)
  hosts = {
    router = "192.168.99.1";
    mgmt   = "192.168.99.10";
    media  = "192.168.99.20";   # set to the real IP
  };
};
```

When `enable = true`:

- Unbound answers `router.lan`, `mgmt.lan`, `media.lan` … (static
  `local-data`; the `hosts` attrset drives both names + addresses).
- Kea advertises `<domain>` as the DHCP search domain, so bare `media`
  resolves on clients (best-effort per client — see quirks).
- Hosts **not** in the list keep using normal recursive DNS — nothing breaks.

**Known quirks** (why it's opt-in — expect to iterate):

- **Dynamic DHCP IPs**: a VM on DHCP may change address, so its name would
  point at a stale IP. Fix = give it a Kea host **reservation** (MAC → fixed
  IP) or a static IP, then add it to `hosts`.
- **Search domain**: some clients (Android/iOS, some TVs) ignore the DHCP
  option — they'll need the full `media.lan` form.
- **`lan` vs `home.arpa`**: `home.arpa` is the IANA-reserved name; `.lan` is
  historical. Pick one and stick to it.
- Changing `internalDns` settings = `nixos-rebuild switch` on the router, then
  `nixos-rebuild switch` again on any host whose IP/name you changed.

Debug on the router: `dig media.lan @127.0.0.1`, `dig -x <ip> @127.0.0.1`,
`journalctl -u unbound -f`.

## Verify after boot

```sh
# from a LAN client (or the mgmt host):
ipconfig /all         # Windows: router=192.168.99.1, DNS=192.168.99.1
nslookup example.com  # resolves via Unbound
curl -I http://example.com   # NAT works out to the internet

# on the router itself:
nixos-rebuild switch --flake /etc/nixos#edge-router   # after pushing changes
journalctl -u kea-dhcp4 -f
journalctl -u unbound -f
curl -s localhost:9100/metrics | head                # node_exporter up
```

## Ports

| Port(s) | Proto | Listen | Purpose |
| --- | --- | --- | --- |
| 67/68 | UDP | LAN (trusted) | Kea DHCP server |
| 53 | TCP+UDP | `192.168.99.1` (+ loopback) | Unbound recursive DNS |
| 9100 | TCP | `192.168.99.1` | node_exporter (scraped by `mgmt`) |
| 22 | TCP | all | SSH (key-only) |

WAN policy: unsolicited inbound is **dropped**; the firewall trusts the LAN
interface wholesale.

## Hardening before leaving the lab

- `passwd` (both `drn` and root) — `changeme` is a placeholder.
- Replace `openssh.authorizedKeys.keys` if you don't use `hi@drn.ie`.
- Add `system.autoUpgrade` and `services.fail2ban` like `hosts/app-node`
  once you're happy it's stable.
