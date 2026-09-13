# AGENTS.md

Nix flake repo: NixOS + Home-Manager config for several machines. Flake-only
(`nixpkgs` unstable + `home-manager` master, shared lockfile). Host table and
per-node docs in `README.md`; ops docs live in `docs/` or each host's README.

## Commands

- `home-switch` (alias `hm`) — switch Home-Manager for this machine:
  `home-manager switch --flake .#$USER@$HOSTNAME -b backup` (defined in
  `home/configs/bash.nix`)
- `make switch-hm` / `make build-hm` — same via Makefile (defaults to
  `#<user>@<hostname>`)
- `nixos-rebuild switch --flake .#<host>` — NixOS hosts (proxmox nodes, router)
- `nix build .#nixosConfigurations.<host>.config.system.build.VMA` — Proxmox VM image
- `nix flake update` — bump lockfile

## Layout

- `hosts/<host>/` — NixOS configs (`default.nix`, `hardware-configuration.nix`, `proxmox.nix`)
- `home/` — shared Home-Manager config; `configs/*.nix` imported from `home/home.nix`
- `scripts/`, `manifests/` — node-specific tooling and k3s manifests

## Conventions

- Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`)
- Formatter: `nixpkgs-fmt` (flake `formatter.x86_64-linux`) — run `nix fmt` before commit
- New home-manager configs: add the file under `home/configs/` and import it in `home/home.nix`
- Uncommitted working tree is normal here; commit in conventional-commit themed batches

## Changing machines

NEVER change a machine directly — no ad-hoc package installs, no editing
files on hosts by hand, no sshing in to tweak something. All changes to a
machine's state flow through this repo: edit the config here, commit, then
switch the machine from the flake (`nixos-rebuild switch --flake .#<host>`
on NixOS hosts, `home-manager switch` / `home-switch` on standalone
machines, or the `make deploy-*` targets — which ssh to each host, pull this
repo, and switch it from the flake).
