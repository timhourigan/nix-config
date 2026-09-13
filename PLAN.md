# Plan: Commit existing changes

## Context

The working tree has a large batch of uncommitted work. The user asked to
commit it. Repo convention is [Conventional Commits](https://www.conventionalcommits.org/)
(`feat:` / `fix:` / `docs:`), no hooks, no commit template. Local branch is
4 commits ahead of `origin/main` — push is **out of scope** unless requested.

## What's in the tree (23 files: 4 staged, 19 unstaged, 0 untracked)

The changes cluster into four themes — which is the natural split if the user
wants more than one commit:

### 1. Proxmox image builds (VMA)

- `hosts/app-node/proxmox.nix` — **new**: lkl `mem=100M→4096M` overlay,
  `virtualisation.diskSize = 40960`, qemuConf (seabios, 2 cores, vmbr0, agent bool)
- `hosts/media/proxmox.nix` — diskSize → canonical `virtualisation.diskSize`, `agent = "1"` → `true`
- `hosts/rocinante/proxmox.nix` — same, plus `filenameSuffix` "media" → "rocinante" (copy-paste fix)
- `hosts/app-node/hardware-configuration.nix` — root device → `/dev/disk/by-label/nixos` via `lib.mkDefault` (staged) + comment header rewrite (unstaged)
- `flake.nix` — wires `proxmox-image.nix` + `proxmox.nix` into app-node (unstaged, belongs to this theme)

### 2. 2026 nixpkgs / home-manager compatibility

- `flake.lock` — home-manager, nixpkgs.lib, nixos-generators, nixpkgs all bumped
- `home/configs/git.nix` — aliases/userName/userEmail/extraConfig → unified `settings`
- `home/configs/neovim.nix` + **deletes** `home/configs/neovim-unwrapped/{package.nix, system_rplugin_manifest.patch, treesitter-parsers.nix}` — vendored copy dropped; withRuby/withPython3 pinned; coc-python/coc-go removed
- `home/home.nix` — `genericLinux.gpu.enable = false`; package renames (bitwarden-desktop, dust, loco, fastfetch, nixfmt, taskwarrior2, noto-fonts-color-emoji); `nerdfonts.override` → individual `nerd-fonts.*` pkgs; python311 → python312
- `home/configs/firefox.nix` — `configPath = ".mozilla/firefox"` (silences warning)
- `home/configs/vscode.nix` — extensions/settings restructured under `profiles.default`

### 3. app-node runtime fixes

- `hosts/app-node/default.nix` — `networking.networkmanager.enable = true` (DHCP); `security.sudo.extraRules = []`; new one-shot `make-k3s-kubeconfig-readable` systemd service (chmod 644 + copy to `/home/darren/.kube/config`)

### 4. Docs

- `README.md`, `docs/architecture.md`, `docs/backup-restore.md`,
  `docs/disk-resize.md`, `docs/provisioning.md` — proxmox-image workflow, path renames
- `hosts/app-node/README.md` — "deploy from built Proxmox image" section
- `hosts/kube/README.md` — obsolete-k0s warning banner

## Approach — depends on user's answer (see questions)

Single commit: `git add -A` then one Conventional Commit message.

Split (recommended, matches the four themes above): stage each theme
separately, commit in order (compat → proxmox → app-node → docs, or
proxmox first since part of it is already staged).

Suggested messages:

- `feat(proxmox): build VMA images for app-node; fix diskSize/agent on media & rocinante`
- `chore(home): update 2026 nixpkgs/home-manager (pkg renames, nerd-fonts, neovim wrapper drop, git settings)`
- `fix(app-node): enable DHCP; world-readable k3s kubeconfig`
- `docs: proxmox image workflow, app-node deploy walkthrough, k0s obsoletion`

## Files to modify (for the commit operation)

No source edits — only `git add` / `git commit`. Files touched listed in
"What's in the tree" above.

## Verification

- `git status` — clean after commit(s)
- `git log --oneline -N` — commit(s) present with final messages
- Optionally `git show --stat <sha>` per commit to confirm theme grouping

## Out of scope

- `git push` (4 commits already ahead; not requested)
- Rebuilding the flake (no Nix evaluation requested)
