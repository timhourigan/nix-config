default: help

.PHONY: build-hm
build-hm: ## Build Home-Manager configurations
	home-manager build --flake .

.PHONY: build-nixos
build-nixos: ## Build NixOS configuration
	nixos-rebuild build --flake .

.PHONY: lock
lock: ## Update lock file
	nix flake update

.PHONY: help
help: ## This menu
	@grep -P "##\s(.*)$$" $(MAKEFILE_LIST) | sed 's/:.*##/:/'
