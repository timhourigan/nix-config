#!/usr/bin/env bash
# Full app-node deploy: pull + rebuild the NixOS config, then rebuild and
# redeploy the curam-fitness app. Run ON the VM, or from your dev machine via
# `make deploy-app-node` (ssh) — this script targets app-node specifically.
#
# Usage: ./scripts/deploy-app.sh [app-dir] [nix-config-dir]
#   app-dir        path to the curam/fitness repo (default: /opt/curam/fitness)
#   nix-config-dir path to this repo on the VM    (default: /opt/nix-config)

set -euo pipefail

APP_DIR="${1:-/opt/curam/fitness}"
NIX_CONFIG="${2:-/opt/nix-config}"
FLake_REF="app-node" # the host this script deploys to

if [ ! -d "$APP_DIR" ]; then
    echo "❌ App repo not found at $APP_DIR — clone it first:"
    echo "   sudo git clone git@github.com:darrenmeehan/curam-fitness $APP_DIR"
    exit 1
fi
if [ ! -f "$NIX_CONFIG/secrets/curam-secrets.enc.yaml" ]; then
    echo "❌ $NIX_CONFIG/secrets/curam-secrets.enc.yaml missing — run scripts/setup-secrets.sh once"
    exit 1
fi

echo "==> Pulling nix-config + rebuilding NixOS config"
git -C "$NIX_CONFIG" pull
sudo nixos-rebuild switch --flake "$NIX_CONFIG#$FLake_REF"

echo "==> Pulling app repo"
git -C "$APP_DIR" pull

echo "==> Building + loading app image"
"$NIX_CONFIG/scripts/build-app.sh" "$APP_DIR"

echo "==> Applying manifests + secrets"
kubectl apply -k "$NIX_CONFIG/manifests/curam-fitness/"
sops --decrypt "$NIX_CONFIG/secrets/curam-secrets.enc.yaml" | kubectl apply -f -

echo "==> Rolling out backend"
kubectl -n curam-fitness rollout restart deployment/backend
kubectl -n curam-fitness rollout status deployment/backend --timeout=180s
kubectl -n curam-fitness get pods
