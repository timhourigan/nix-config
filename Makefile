default: help

HOSTNAME=$(shell hostname)

# `nixos-rebuild` will use the current host, if none is specified
.PHONY: build-nixos
build-nixos: ## Build NixOS configuration
	nixos-rebuild build --flake .

# `nixos-rebuild` will use the current host, if none is specified
.PHONY: switch-nixos
switch-nixos: ## Switch NixOS configuration
	nixos-rebuild switch --flake .

.PHONY: bootstrap-hm
bootstrap-hm: ## Bootstrap Home-Manager configuration
	nix build --no-link .#homeConfigurations.$(USER)@$(HOSTNAME).activationPackage
	$(shell nix path-info .#homeConfigurations.$(USER)@$(HOSTNAME).activationPackage)/activate

.PHONY: build-hm
build-hm: ## Build Home-Manager configuration
	home-manager build --flake .#$(USER)@$(HOSTNAME)

.PHONY: switch-hm
switch-hm: ## Switch Home-Manager configuration
	home-manager switch --flake .#$(USER)@$(HOSTNAME)

.PHONY: deploy-app-node
deploy-app-node: ## Full deploy on app-node: NixOS config + app (requires Tailscale)
	ssh -t darren@app-node /opt/nix-config/scripts/deploy-app.sh

PROVISION_HOST ?= app-node
VMID ?= 100
PVE ?= root@pve
.PHONY: provision-vm
provision-vm: ## Provision a VM on PVE from a built VMA image (PROVISION_HOST=media VMID=101 PVE=root@pve)
	./scripts/provision-vm.sh "$(PROVISION_HOST)" "$(VMID)" "$(PVE)"

.PHONY: deploy-media
media: ## Pull + switch the media VM (requires Tailscale/ssh)
	ssh drn@media 'cd /opt/nix-config && git pull && sudo nixos-rebuild switch --flake /opt/nix-config#media'

.PHONY: lock
lock: ## Update lock file
	nix flake update

.PHONY: gc
gc: ## Garbage collect
	nix-collect-garbage

.PHONY: help
help: ## This menu
	@grep -P "##\s(.*)$$" $(MAKEFILE_LIST) | sed 's/:.*##/:/'
