#!/usr/bin/env python3
"""Map the edge-router's physical ethernet ports to interface names.

Run this ON the router (or its installer), once, after plugging in your cables.
It shows the real interface names (a 6-port NIC enumerates as ``enp1s0f*`` /
``enpNsM`` in a way that rarely matches the front-panel labels) and blinks each
port's LED so you can assign them, then writes ``wan`` and ``lanPorts`` into
``hosts/edge-router/default.nix``.

Usage:
    scripts/edge-router-netconf.py                     # auto-locate config
    ROUTER_NIX=hosts/edge-router/default.nix scripts/edge-router-netconf.py

Only ``wan`` and ``lanPorts`` are touched; the rest of the config (bridge,
NAT, firewall, Kea subnet, DNS) is left alone.
"""

from __future__ import annotations

import contextlib
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Interface names that are never physical LAN/WAN ports.
VIRTUAL_PREFIXES = ("lo", "docker", "veth", "br", "tailscale")
# candidate config locations, in order
CONFIG_CANDIDATES = (
    Path("hosts/edge-router/default.nix"),
    Path("/etc/nixos/hosts/edge-router/default.nix"),
    Path("/root/nix-config/hosts/edge-router/default.nix"),
    Path.home() / "nix-config" / "hosts" / "edge-router" / "default.nix",
)

WAN_RE = re.compile(r"^(\s*wan = \")[^\"]*")
LANPORTS_RE = re.compile(r"^(\s*lanPorts = )\[.*\];")


def find_config() -> Path:
    """Locate the edge-router config, honouring ``ROUTER_NIX``."""
    override = os.environ.get("ROUTER_NIX")
    candidates = [Path(override)] if override else CONFIG_CANDIDATES
    for path in candidates:
        if path.exists() and path.is_file():
            return path.resolve()
    print(
        "error: could not find hosts/edge-router/default.nix "
        "(set ROUTER_NIX=/path/to/default.nix)",
        file=sys.stderr,
    )
    sys.exit(1)


def enumerate_nics() -> list[str]:
    """Return the physical ethernet interface names on this box."""
    names: list[str] = []
    for path in Path("/sys/class/net").iterdir():
        if not path.is_dir():
            continue
        name = path.name
        if name.startswith(VIRTUAL_PREFIXES):
            continue
        # physical NICs have a `device` symlink
        if not (path / "device").is_symlink():
            continue
        # bring it up so carrier reflects a plugged cable (mirrors `ip link set up`)
        with contextlib.suppress(FileNotFoundError):
            subprocess.run(
                ["ip", "link", "set", "dev", name, "up"],
                check=False,
                capture_output=True,
            )
        names.append(name)
    return names


def blink(name: str, seconds: int = 2) -> None:
    """Blink an interface's port LED for a short confirm."""
    with contextlib.suppress(FileNotFoundError):
        subprocess.run(
            ["ethtool", "-p", name, str(seconds)],
            check=False,
            capture_output=True,
        )


def read_line(prompt: str) -> str:
    return input(prompt).strip()


def pick_assignment(names: list[str]) -> dict[str, str]:
    """Ask the user which front-panel port each interface is; return iface→label."""
    print("Blinking each interface's port LED (label the ports as you go)...")
    assignment: dict[str, str] = {}
    for name in names:
        try:
            mac = (Path("/sys/class/net") / name / "address").read_text().strip()
        except OSError:
            mac = "?"
        value = read_line(
            f"  * {name} (MAC {mac}): what physical port is this "
            "(e.g. P1/P2/P3…, or 'none' to skip)? "
        )
        lowered = value.lower()
        if not value or lowered in ("none", "n"):
            continue
        assignment[name] = value
        blink(name)
    return assignment


def pick_wan(assignment: dict[str, str]) -> str:
    endpoint = {label: iface for iface, label in assignment.items()}
    while True:
        choice = read_line("Which port is WAN (upstream modem / office network)? ")
        if choice in endpoint:
            return endpoint[choice]
        print("  (enter a port label you assigned above)")


def write_config(config: Path, wan: str, lan_ports: list[str]) -> None:
    """Rewrite ``wan`` and ``lanPorts`` in place, keeping a ``.bak``."""
    shutil.copyfile(config, f"{config}.bak")
    lan_list = "[ " + " ".join(f'"{p}"' for p in lan_ports) + " ]"
    lines = config.read_text().splitlines()
    for i, line in enumerate(lines):
        if WAN_RE.match(line):
            lines[i] = WAN_RE.sub(rf"\g<1>{wan}", line)
        elif LANPORTS_RE.match(line):
            lines[i] = LANPORTS_RE.sub(rf"\g<1>{lan_list};", line)
    config.write_text("\n".join(lines) + "\n")


def main() -> None:
    config = find_config()
    print(f"config: {config}\n")

    names = enumerate_nics()
    if not names:
        print(
            "error: no physical ethernet interfaces found. Is this the router?",
            file=sys.stderr,
        )
        sys.exit(1)

    print(
        f"Found {len(names)} ethernet interface(s). Each cable plugged in shows up "
        "here; I'll blink them so you can match front-panel ports.\n"
    )

    assignment = pick_assignment(names)
    if not assignment:
        print("error: no ports assigned", file=sys.stderr)
        sys.exit(1)

    print("\nAssignments:")
    for iface, label in assignment.items():
        print(f"  {iface}:{label}")
    print()

    wan = pick_wan(assignment)
    lan_ports = [iface for iface in assignment if iface != wan]
    if not lan_ports:
        print("error: need at least one LAN port besides WAN", file=sys.stderr)
        sys.exit(1)

    write_config(config, wan, lan_ports)
    print(f"Updated {config} (backup: {config}.bak):")
    for line in config.read_text().splitlines():
        if line.lstrip().startswith(("wan =", "lanPorts =", 'wan = "', "lanPorts = [")):
            print(f"  {line}")

    # repo root is ../.. from hosts/edge-router
    repo_root = config.parent.parent.parent
    print(
        "\nNext: rebuild on the box —\n"
        f"  sudo nixos-rebuild switch --flake {repo_root}#edge-router"
    )


if __name__ == "__main__":
    main()
