#!/usr/bin/env bash
# Provision a fresh Proxmox VM from a built VMA image (the "no ISO"
# workflow from hosts/app-node/README.md, scripted). Run on your dev machine.
#
# Usage: ./scripts/provision-vm.sh <host> [vmid] [pve]
#   host  NixOS configuration to build the image from (app-node, media, rocinante)
#   vmid  VMID to restore into (default: 100)
#   pve   SSH target for the Proxmox host (default: root@pve)
#
# Requires: ssh root access to the PVE host, scp, and this flake (nix build).

set -euo pipefail

HOST="${1:?usage: provision-vm.sh <host> [vmid] [pve]}"
VMID="${2:-100}"
PVE="${3:-root@pve}"
VMA="result/vzdump-qemu-${HOST}.vma.zst"
DUMP_DIR="/var/lib/vz/dump"

cd "$(dirname "$0")/.." # repo root — result/ lives next to scripts/

# 1. Bake the current flake config into a fresh image.
echo "==> Building VMA image for ${HOST}"
nix build ".#nixosConfigurations.${HOST}.config.system.build.VMA"

# 2. Refuse to clobber an existing VM.
if ssh "$PVE" "qm config $VMID" >/dev/null 2>&1; then
    echo "❌ VM $VMID already exists on $PVE — pick a free VMID:"
    echo "   ./scripts/provision-vm.sh $HOST <vmid>"
    exit 1
fi

# 3. Upload, verify, restore, start.
echo "==> Uploading $VMA to $PVE:$DUMP_DIR/"
scp "$VMA" "$PVE:$DUMP_DIR/"
ssh "$PVE" "test -f $DUMP_DIR/vzdump-qemu-${HOST}.vma.zst" ||
    {
        echo "❌ Uploaded file missing on $PVE ($DUMP_DIR/). Check where your vzdump backup storage lives."
        exit 1
    }
# Absolute path: qmrestore resolves a bare filename against the default
# backup storage, which may differ from this node's /var/lib/vz/dump.
ssh "$PVE" "qmrestore $DUMP_DIR/vzdump-qemu-${HOST}.vma.zst $VMID"
ssh "$PVE" "qm start $VMID"

echo "✅ VM $VMID ($HOST) started on $PVE"
echo ""
echo "First boot (find <lan-ip> on the Proxmox summary):"
echo "  ssh -i ~/.ssh/home-k8s darren@<lan-ip>"
echo "  passwd darren          # required — sudo is not passwordless"
echo "  sudo tailscale up      # approve the auth URL once"
echo "Then deploy (see docs/provisioning.md steps 7-8):"
echo "  ssh darren@$HOST"
echo "  /opt/nix-config/scripts/deploy-app.sh"
