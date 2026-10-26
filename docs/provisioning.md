# Provisioning the VM — step by step

The VM is provisioned **once**, manually, then treated as immutable.
Day-2 changes (OS updates, config, new apps) are declarative via
`nixos-rebuild switch` + `kubectl apply`. This doc covers the one-time
bootstrap only.

> **Two ways to provision:** (A) the manual ISO install below, or (B) the
> prebuilt Proxmox image — `nix build
> .#nixosConfigurations.app-node.config.system.build.VMA`, restore the
> `.vma.zst` with `qmrestore`, and the VM boots already configured (users,
> SSH key, k3s, Docker all baked in). See `hosts/app-node/README.md` →
> "Alternative: deploy from a built Proxmox image" for the exact steps. The
> image path is faster and matches how this flake versions the host; the ISO
> path below is the fallback when you want an interactive install.

---

## Prerequisites (before you start)

| Item | Done? | Install command |
| --- | --- | --- |
| SSH keypair generated (`~/.ssh/home-k8s`) | ☐ | `ssh-keygen -t ed25519 -C "home-k8s" -f ~/.ssh/home-k8s` |
| Public key pasted into `hosts/app-node/default.nix` | ☐ | — |
| **age** installed (provides `age-keygen`) | ☐ | `nix shell nixpkgs#age` or `brew install age` or `sudo apt install age` |
| Age key generated (`~/.config/sops/age/keys.txt`) | ☐ | `age-keygen -o ~/.config/sops/age/keys.txt` |
| Public age key copied into `.sops.yaml` | ☐ | `cat ~/.config/sops/age/keys.txt \| grep "public key:"` |
| Both repos pushed to GitHub (public or private) | ☐ | — |
| NixOS minimal ISO downloaded | ☐ | <https://nixos.org/download> |

> **Note:** NixOS needs internet access during install. Your Proxmox VM must
> have a network bridge (vmbr0) — default for most templates.

---

## Step 1 — Create the VM in Proxmox

1. Open Proxmox web UI → **Create VM** (top-right)
2. General: name `app-node`, VM ID e.g. `100`
3. OS: select the NixOS ISO (from local storage or upload it first)
4. System: default (SeaBIOS or OVMF both work; match the ISO)
5. Disk: 40GB, `virtio-scsi` or `virtio-blk`
6. CPU: 2 cores, type `host`
7. Memory: 4096 MB (4GB)
8. Network: bridge `vmbr0`, model `virtio`
9. Finish. Don't start it yet.

**Boot order**: set CD-ROM first so it boots the ISO.

---

## Step 2 — Boot the NixOS installer

1. Start the VM, open the console
2. NixOS minimal boots to a root shell (no login needed)
3. Verify network:

   ```bash
   ip a            # check you have an IP
   ping -c 1 github.com   # confirm internet
   ```

---

## Step 3 — Install NixOS from the flake

The flake is on GitHub, so the installer can fetch it directly.

```bash
# Set up networking if DHCP didn't work (rare)
# dhcpcd  (or: ip link set ens18 up && dhcpcd ens18)

# Install from the flake
nixos-install --flake github:darrenmeehan/nix-config#app-node

# It will ask:
#   - Which disk to partition (select /dev/vda — the 40GB virtio disk)
#   - Set a root password (or it generates one to display)
```

**If the flake URL is wrong or unreachable** — clone it locally first:

```bash
git clone https://github.com/darrenmeehan/nix-config /tmp/nix-config
cd /tmp/nix-config
nixos-install --flake .#app-node
```

---

## Step 4 — Reboot

```bash
reboot
```

Remove the ISO from the VM's CD-ROM (Proxmox UI → Hardware → CD/DVD Drive →
Remove) or just set boot order to disk-first.

---

## Step 5 — First login

```bash
# From your dev machine:
ssh -i ~/.ssh/home-k8s darren@<vm-ip>
```

If the VM's IP changed after reboot, find it in the Proxmox console:
`ip a`.

If SSH doesn't work, check:

- `systemctl status sshd`
- `hosts/app-node/default.nix` has the right public key
- The install actually applied the flake (it should have — authorizedKeys
  was baked in)

---

## Step 6 — Authenticate Tailscale

```bash
sudo tailscale up
# Prints a URL — open it in your browser, log in
# VM joins your tailnet
```

Once authenticated, you can reach the VM from any device:
`ssh -i ~/.ssh/home-k8s darren@app-node` (MagicDNS name).

---

## Step 7 — Clone the repos + deploy

```bash
sudo git clone https://github.com/darrenmeehan/nix-config /opt/nix-config
cd /opt/nix-config

# Generate + encrypt secrets (asks for API keys)
./scripts/setup-secrets.sh

# Build the fitness app image
sudo git clone https://github.com/darrenmeehan/curam-fitness /opt/curam/fitness
./scripts/build-app.sh /opt/curam/fitness

# Deploy
kubectl apply -k manifests/curam-fitness/

# Watch it come up
kubectl -n curam-fitness get pods -w
```

---

## Step 8 — Verify

```bash
curl -s http://localhost:8080/api/health
# → {"database":"connected","status":"healthy"}

# From your phone (Tailscale app installed, same account):
# Open http://app-node/  (or the MagicDNS hostname)
```

---

## Day-2 operations

```bash
# Full deploy (config + app) in one command — run on the VM:
/opt/nix-config/scripts/deploy-app.sh
# …or from your dev machine:
#   make deploy-app-node

# Manual split version:
# Update the OS + config (from dev machine, after git push):
ssh darren@app-node
cd /opt/nix-config && git pull
sudo nixos-rebuild switch --flake /opt/nix-config#app-node

# Update the app:
cd /opt/curam/fitness && git pull
/opt/nix-config/scripts/build-app.sh /opt/curam/fitness
kubectl -n curam-fitness rollout restart deploy/backend
```

---

## If you need to redo the VM (disaster)

1. Delete the VM in Proxmox
2. Either repeat steps 1-4 (create VM, boot ISO, nixos-install) **or** build
   and restore the prebuilt image (see the box at the top of this doc)
3. Tailscale re-auth
4. Clone repos
5. `sops --decrypt secrets/curam-secrets.enc.yaml | kubectl apply -f -`
6. Restore Postgres from the last dump (see `backup-restore.md`)
7. Rebuild the image, apply manifests

Everything needed to rebuild is in git. The only secrets not in git are the
age private key and the API keys — keep those in a password manager.

---

## Automating VM creation (future, not needed yet)

Once this manual flow works, you can automate steps 1-4:

| Tool | What it buys you |
| --- | --- |
| **`scripts/provision-vm.sh`** | Already here: builds the VMA image, uploads to PVE, `qmrestore` + `qm start` (steps 1-4, no console) |
| **Packer** | Bake NixOS into a Proxmox template; clone → boot with config |
| **Proxmox API** | Create the VM itself from a script (no ssh/scp to PVE) |
| **Terraform** | Declarative VMs + networking alongside the cluster config |

Add these only when you're creating VMs regularly. For one node, manual is
simpler and the flake already makes the *state* reproducible.
