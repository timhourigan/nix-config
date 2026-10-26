# app-node — declarative NixOS + k3s app platform

**Application-agnostic** single-node k3s cluster on Proxmox, managed as part of
this nix-config flake. The first app deployed on it is **Curam Fitness** (see
below), but the host itself has no app-specific assumptions — any containers/
manifests in `manifests/` can live here.

Accessible from anywhere via Tailscale. Zero cloud bill, zero open ports.

Consolidated here from the old `home-k8s` repo (which pinned its own nixpkgs
and was never deployed). The host now follows this flake's single `nixpkgs`
input, so there's one lockfile to maintain.

> **Why the name:** the box runs k3s — a general app platform. `fitness-node`
> implied it only hosted one app; `app-node` is what it actually is.

## Principles

| Principle | How |
| --- | --- |
| **Declarative** | This NixOS flake, not bash scripts |
| **No open ports** | Tailscale WireGuard — no port forwarding |
| **Zero cloud bill** | Runs on Proxmox at home |
| **Encrypted secrets** | `sops` + age, not base64 |
| **Plain YAML** | K8s manifests, not Helm (until patterns repeat) |

## Stack

| Layer | Choice |
| --- | --- |
| OS | NixOS (follows flake `nixpkgs`) |
| Container runtime | Docker (for building) + containerd (k3s) |
| K8s | k3s (single-node, embedded SQLite, no etcd) |
| VPN | Tailscale (WireGuard) |
| Proxy | Tailscale Serve (auto TLS) |
| Secrets | sops + age |
| Backups | pg_dump cron + k3s snapshot |

## Structure

```
hosts/app-node/
  default.nix                 # Host config: hostname, users, packages
  modules/
    tailscale-serve.nix       # Tailscale Serve proxy :80 → backend
    docker.nix                # Docker daemon + auto-prune
manifests/
  curam-fitness/              # K8s YAML for the fitness app
    namespace.yaml
    postgres.yaml
    backend.yaml
    cron-backup.yaml
    kustomization.yaml
scripts/
  build-app.sh                # Docker build + load into k3s
  setup-secrets.sh            # Generate + sops-encrypt secrets
secrets/
  curam-secrets.enc.yaml      # Encrypted (safe to git commit)
```

k3s itself uses the native NixOS `services.k3s` module (see `default.nix`),
with `--disable=traefik`/`--disable=servicelb` and the control-plane
components bound to loopback.

## Before you start — SSH keypair

You need an SSH key to access the VM. Generate one on your **dev machine**
(laptop/desktop, not the VM):

```bash
ssh-keygen -t ed25519 -C "home-k8s" -f ~/.ssh/home-k8s
```

This creates two files:

| File | Purpose | Where it goes |
| --- | --- | --- |
| `~/.ssh/home-k8s` | **Private key** — never share, never commit | Stays on your dev machine |
| `~/.ssh/home-k8s.pub` | **Public key** — safe to share | Pasted into `hosts/app-node/default.nix` |

To see your public key:

```bash
cat ~/.ssh/home-k8s.pub
# → ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... home-k8s
```

Copy that entire line, then open `hosts/app-node/default.nix` and make
sure your public key is listed under `users.users.darren.openssh.authorizedKeys.keys`
(it already is — only touch it if you rotate the key).

## Alternative: deploy from a built Proxmox image (no ISO)

Instead of installing from the ISO (steps 1 + 4 in "First-time setup"), you
can build a ready-to-boot Proxmox image from this flake and restore it
straight into a VM. Disk layout, users, SSH keys and services are all baked
in — you don't touch the console.

### 1. Build the image — *dev machine*

```bash
nix build .#nixosConfigurations.app-node.config.system.build.VMA
# → result/vzdump-qemu-app-node.vma.zst
```

### 2. Deploy to Proxmox — *dev machine + PVE host*

```bash
scp result/vzdump-qemu-app-node.vma.zst root@pve:/var/lib/vz/dump/
# on pve:
qmrestore vzdump-qemu-app-node.vma.zst 100   # any free VMID
qm start 100
```

### 3. Log in — *dev machine*

SSH is key-only (`PasswordAuthentication = false`) and only `home-k8s` is
authorized (see "Before you start — SSH keypair" above). On first boot the VM
is reachable on its LAN IP (listed on the Proxmox summary; DHCP on `vmbr0`):

```bash
ssh -i ~/.ssh/home-k8s darren@<lan-ip>
passwd darren          # set a password first — sudo is NOT passwordless
```

Make it reusable by adding `~/.ssh/config`:

```
Host app-node
  HostName <lan-ip-or-tailscale-name>
  User darren
  IdentityFile ~/.ssh/home-k8s
```

### 4. Join Tailscale — *first SSH session on the VM*

```bash
passwd darren          # required — sudo prompts for this
sudo tailscale up      # prints an auth URL; approve once
```

After that, `ssh darren@app-node` works from anywhere via MagicDNS, and
steps 6–8 of "First-time setup" (clone repo, secrets, app) apply as normal.

> The built image is not automatically rebuilt when you change the flake —
> re-run step 1 and redeploy to pick up config changes before first boot, or
> use `sudo nixos-rebuild switch` on the VM once it's cloned (`git clone
> <repo> /opt/nix-config`).

## The bash scripts — what they do

### `scripts/setup-secrets.sh` (run once, first deploy) — **run on the VM**

One-time setup. Generates random passwords for the database, JWT signing,
and webhook signing. Prompts for the Anthropic API key (AI coaching) and
Resend API key (emails, optional). Assembles them into a k8s Secret YAML,
then encrypts it with `sops` using your age key. The encrypted file
(`secrets/curam-secrets.enc.yaml`) is safe to commit to git.

Does NOT touch the running cluster. Output is a file.

### `scripts/build-app.sh` (run every time you update the app) — **run on the VM**

Builds the Docker image from the `curam/fitness` repo, then loads it into
k3s's built-in containerd so k3s can use it without a registry. Takes an
optional path to the app repo (defaults to `/opt/curam/fitness`) and an
optional tag (defaults to a timestamp).

After running, you need to tell k3s to use the new image:
`kubectl -n curam-fitness rollout restart deploy/backend`

### `scripts/deploy-app.sh` (every deploy — OS + app) — **run on the VM**

The full day-2 deploy in one command: pull + `sudo nixos-rebuild switch` for
the NixOS config, pull + rebuild the app image, apply manifests + the
sops-encrypted secret, restart the backend and wait for it to come up.

```bash
/opt/nix-config/scripts/deploy-app.sh
```

From your dev machine, `make deploy-app-node` wraps this in an ssh call.

### `scripts/provision-vm.sh` (new VMs only) — **run on your dev machine**

Builds a fresh VMA image for a host, uploads it to the PVE host, restores it
into a new VM and starts it — the "Alternative: deploy from a built Proxmox
image" flow above, scripted. Aborts if the VMID is already in use, then
prints the first-boot checklist (password, Tailscale, first deploy).

```bash
./scripts/provision-vm.sh app-node 101   # or: make provision-vm VMID=101
```

## First-time setup

> **Where to run each command:** "dev machine" = your laptop, "VM" = the
> NixOS VM. Steps are ordered — do them top to bottom.

### 1. Create Proxmox VM — *Proxmox web UI*

Download the NixOS minimal ISO to the Proxmox host, upload it to storage,
and create the VM booting from it:

```
NixOS minimal ISO (install medium)
2 vCPU, 4GB RAM, 40GB disk
```

### 2. Generate SSH key + add to default.nix — *dev machine*

```bash
ssh-keygen -t ed25519 -C "home-k8s" -f ~/.ssh/home-k8s
cat ~/.ssh/home-k8s.pub
# Paste the output into hosts/app-node/default.nix
```

### 3. Generate age key + add to .sops.yaml — *dev machine*

```bash
age-keygen -o ~/.config/sops/age/keys.txt
cat ~/.config/sops/age/keys.txt | grep "public key:"
# Copy the age1... key into .sops.yaml
```

### 4. Install NixOS — *VM, from the ISO attached in step 1*

```bash
# Boot from NixOS minimal ISO, then:
sudo nixos-install --flake github:darrenmeehan/nix-config#app-node
```

> This flake does **not** expose a `system.build.iso` for app-node — if
> you'd rather skip the ISO dance entirely, use the prebuilt Proxmox image
> flow in "Alternative: deploy from a built Proxmox image" above instead.

### 5. Set a password, then authenticate Tailscale — *VM*

```bash
passwd darren          # ← REQUIRED: sudo won't work until a password is set
sudo tailscale up      # prompts for the password you just set
# Follow the URL to authenticate
```

> **Why `passwd` first:** the image creates `darren` with **no password** and
> **no NOPASSWD sudo** (removed deliberately). SSH is key-only, but `sudo`
> needs a password — set one before any `sudo`.

### 6. Confirm the baked kubectl fix — *VM*

```bash
kubectl get nodes      # should list app-node — no sudo needed
```

The image ships a systemd unit that copies k3s's admin kubeconfig to
`/home/darren/.kube/config` after k3s starts, so the plain `kubectl` works
for `darren`. If it errors, k3s may still be starting — check `systemctl
status k3s` and retry.

### 7. Clone this repo + secrets — *VM*

```bash
sudo install -d -o darren -g darren /opt/nix-config
cd /opt/nix-config && git clone https://github.com/darrenmeehan/nix-config /opt/nix-config
```

(If the clone hangs, the repo is private — use `git@github.com:darrenmeehan/nix-config` with an SSH key added on GitHub.)

Generate an age key and put its public key into `.sops.yaml` (the repo copy
still has a placeholder):

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
grep "public key" ~/.config/sops/age/keys.txt   # copy the age1... line
# Edit .sops.yaml: replace age1your-public-key-here-replace-this with yours,
# then commit that change (the pubkey is safe to commit; keys.txt is NOT).
```

### 8. Deploy the app — *VM*

```bash
# secrets (prompts for Anthropic + Resend API keys)
./scripts/setup-secrets.sh

# cluster resources + the secret
kubectl apply -k manifests/curam-fitness/
sops --decrypt secrets/curam-secrets.enc.yaml | kubectl apply -f -

# app image
sudo git clone git@github.com:darrenmeehan/curam-fitness /opt/curam/fitness
cd /opt/curam/fitness
/opt/nix-config/scripts/build-app.sh /opt/curam/fitness   # sudo prompts → your password
kubectl -n curam-fitness rollout restart deployment/backend
kubectl -n curam-fitness get pods -w
```

### 9. Verify — *VM*

```bash
kubectl -n curam-fitness get pods          # all Running/Ready
curl -s http://localhost:8080/api/health   # {"database":"connected",...}
```

### 10. Access from phone

Install Tailscale, log in with the same account.
Open `http://app-node/` (HTTPS via Tailscale magic).

## Backup strategy

### What we back up now

| Data | Method | Frequency | Location |
| --- | --- | --- | --- |
| Postgres | `pg_dump` via CronJob | Weekly (Sun 3am) | `/var/backups/app/` on VM |
| k3s cluster state | Built-in snapshot | Every 12h | `/var/lib/rancher/k3s/server/db/snapshots/` |

### Options for database backups

| Option | Pros | Cons | Verdict |
| --- | --- | --- | --- |
| **Current: local host path** | Simple, no dependencies | Lost if VM disk dies, no offsite | Fine for now |
| **Tailscale + rsync to your laptop** | Offsite, no cloud bill, encrypted in transit | Requires laptop to be on, manual | Easy next step |
| **Tailscale + rsync to another Proxmox VM** | Offsite within the same server, automated | Not truly offsite (same power/rack) | Minor improvement |
| **s3-compatible (Backblaze B2)** | $0.01/GB/mo, automated, truly offsite | Costs money, needs API keys | Best option if you want real offsite |
| **rsync.net** | $0.02/GB/mo, SSH-only, no API needed | Slightly more expensive than B2 | Good alternative to B2 |
| **Cloudflare R2** | $0.015/GB/mo, no egress fees | Needs cloudflare account | Overkill for this scale |
| **pg_dump → gzip → sops encrypt → email** | Zero infra, your email is the backup | Attachment size limits, fragile | Clever but not reliable |

**Current pick**: local host path (already done). If you want offsite, add a
cron job that encrypts the dump with age and rsyncs it to a cheap Backblaze
B2 bucket. ~$0.50/month for years of backups.

### Is it worth backing up config too?

**Yes, but it's already backed up.** The flake + k8s YAML are in git. To
restore from scratch:

1. Install NixOS from the flake
2. `git clone` this repo
3. `sops --decrypt secrets/curam-secrets.enc.yaml | kubectl apply -f -`
4. Rebuild the Docker image from the fitness repo
5. `kubectl apply -k manifests/curam-fitness/`

The only thing NOT in git is the age private key and the Anthropic/Resend API
keys. Those should be backed up separately (password manager, offline USB,
or sops-encrypted and stored somewhere safe).

**What about the k3s cluster state?** Deployments, Services, ConfigMaps are
all in git. PersistentVolumeClaims are Postgres data only. If the VM dies,
you don't need to restore k3s state — you fresh-install NixOS, apply the
manifests, and restore the Postgres dump. The k3s snapshot is a convenience
for faster recovery, not a hard requirement.

## Apps

| App | Namespace | Manifests |
|---|---|---|
| Curam Fitness | `curam-fitness` | `manifests/curam-fitness/` |

## Updating the cluster

```bash
# On dev machine, edit flake or host config, then:
nix flake update
git push

# On the VM — or just run the full deploy (config + app):
#   /opt/nix-config/scripts/deploy-app.sh
cd /opt/nix-config && git pull
sudo nixos-rebuild switch --flake /opt/nix-config#app-node
```

## Updating an app — *VM*

```bash
cd /opt/curam/fitness
git pull
/opt/nix-config/scripts/build-app.sh /opt/curam/fitness
kubectl -n curam-fitness rollout restart deploy/backend
# or the whole OS+app deploy in one go:
# /opt/nix-config/scripts/deploy-app.sh
```
