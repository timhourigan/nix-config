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

.PHONY: lock
lock: ## Update lock file
	nix flake update

.PHONY: gc
gc: ## Garbage collect
	nix-collect-garbage

.PHONY: help
help: ## This menu
	@grep -P "##\s(.*)$$" $(MAKEFILE_LIST) | sed 's/:.*##/:/'
