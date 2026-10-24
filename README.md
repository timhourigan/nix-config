# nix-config

NixOS and Home-Manager configuration for the machines I run:

| Host | What it is | Config |
| --- | --- | --- |
| `edge-router` | CWT N18 Mini PC — Data Plane (NAT/DHCP/DNS) | `hosts/edge-router` |
| `mgmt` | ThinkStation — Management Plane (UniFi/Prometheus/Grafana) | `hosts/mgmt` |
| `media` | Proxmox VM — Jellyfin + *arr stack + Tailscale | `hosts/media` |
| `rocinante` | Proxmox VM | `hosts/rocinante` |
| `app-node` | k3s cluster VM (curam-fitness app) | `hosts/app-node` + `manifests/` |
| `mac@personal` | Home-Manager (standalone) | `home/` |
| `drn@dev` | Home-Manager (standalone) | `home/` |
| `rocinante` | Home-Manager (standalone) | `home/` |
| `darrenmeehan@fedora` | This laptop (Home-Manager, standalone, non-NixOS) | `home/` |

The k3s cluster config was folded in from the old `home-k8s` repo; everything
now shares this flake's single `nixpkgs`/`home-manager` lockfile. Setup and
ops docs live with the node itself: `hosts/app-node/README.md`,
`docs/provisioning.md`, `docs/backup-restore.md`.

Assumes use of Nix flakes.

Agents working in this repo: read `AGENTS.md` for commands, layout, and
commit conventions.

## Adding a new NixOS host

The steps refer to this new host as "example", rename as you see fit.

```shell
cd <parent-dir>/nix-config
mkdir hosts/example
nix-shell -p nixos-install-tools
nixos-generate-config --dir hosts/example
```

## Bringing a non-NixOS Linux machine under management

Standalone Home-Manager works on any Linux (Fedora, Ubuntu, …). For this
laptop (Fedora):

1. Install Nix (reversible via `nix-uninstall`):

   ```shell
   curl -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. Add a `homeConfigurations."<user>@<host>"` entry to `flake.nix` (see the
   `darrenmeehan@fedora` example, which also carries that machine's
   username/home dir and its machine-specific shell env).
3. Either install home-manager and run:

   ```shell
   home-manager switch --flake .#<user>@<host>
   ```

   or bootstrap without installing anything, using the activation package:

   ```shell
   nix build --no-link .#homeConfigurations.<user>@<host>.activationPackage
   $(nix path-info .#homeConfigurations.<user>@<host>.activationPackage)/activate
   ```

   On a machine that already had a hand-written setup this mostly takes
   over `~/.bashrc`, `~/.gitconfig` and `~/.profile`; Home-Manager backs up
   anything it replaces to `*.backup`.

## Update NixOS Configuration

* Build:

```shell
nixos-rebuild build --flake .#<hostname>
```

* Switch (usually requires `sudo`):

```shell
nixos-rebuild switch --flake .#<hostname>
```

## Update Home-Manager Configuration

Use this for non-NixOS machines (this Fedora laptop is `darrenmeehan@fedora`).

* Build:

```shell
home-manager build --flake .#<username>@<hostname>
```

* Switch:

```shell
home-manager switch --flake .#<username>@<hostname>
```

The `darrenmeehan@fedora` config defines a `home-switch` alias (also `hm`) so
you can switch from anywhere:

```shell
home-switch
```

`make switch-hm` / `make build-hm` do the same, deriving `<user>@<hostname>`
from the current login.

## Update flake.lock file

```shell
nix flake update
```

## New Proxmox VM setup

These instructions are based on the NixOS wiki page [Proxmox Virtual Environment](https://nixos.wiki/wiki/Proxmox_Virtual_Environment#Generating_VMA)
and this flake's `proxmox-image.nix` wiring (see `hosts/*/proxmox.nix`).

1. Create a new configuration for the machine
1. Ensure to change the user password hash
1. Generate the machine image using the host's `system.build.VMA` output
   (media, rocinante and app-node all ship one):

    ```shell
    nix build .#nixosConfigurations.<host>.config.system.build.VMA
    # → result/vzdump-qemu-<host>.vma.zst
    ```

1. Upload the image to the Proxmox host

    ```shell
    scp result/vzdump-qemu-<host>.vma.zst root@pve:/var/lib/vz/dump/
    ```

1. Restore the image as a running VM

    ```shell
    # on pve:
    qmrestore vzdump-qemu-<host>.vma.zst <vmid> --unique true
    qm start <vmid>
    ```

> Machine-specific bits (bios/EFI, cores, memory, network bridge, disk size)
> live in each host's `proxmox.nix`; see `hosts/app-node/README.md` for
> the full deploy-and-login walkthrough for that node.

### Resources

[Garbage Collection](https://nixos.org/manual/nix/stable/package-management/garbage-collection.html)

nix run --extra-experimental-features nix-command --extra-experimental-features flakes --no-write-lock-file github:nix-community/home-manager/ -- --flake ".#$USER@$(hostname)" --extra-experimental-features nix-command --extra-experimental-features flakes switch -b backup
