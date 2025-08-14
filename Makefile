HOSTNAME?=$(shell hostname)
NOM=--log-format internal-json -v |& nom --json

.PHONY: default
default: help

.PHONY: all
all: lock test format build ## Lock test format and build

# `nixos-rebuild` will use the current host, if none is specified
.PHONY: build-nixos
build-nixos: ## Build NixOS configuration
	nixos-rebuild build --flake . $(NOM)

.PHONY: build-nixos-all
build-nixos-all: ## Build NixOS configuration for all hosts
	nixos-rebuild build --flake . --target-host m625q.lan $(NOM)
	nixos-rebuild build --flake . --target-host mm.lan $(NOM)
	nixos-rebuild build --flake . --target-host opx7070.lan $(NOM)
	nixos-rebuild build --flake . --target-host sid.lan $(NOM)
	nixos-rebuild build --flake . --target-host x13 $(NOM)

.PHONY: build-nixos-dry-run
build-nixos-dry-run: ## Build NixOS configuration (dry-run)
	nixos-rebuild dry-build --flake .

.PHONY: switch-nixos
switch-nixos: ## Switch NixOS configuration
	nixos-rebuild switch --flake .

.PHONY: bootstrap-hm
bootstrap-hm: ## Bootstrap Home-Manager configuration
	nix build --no-link .#homeConfigurations.$(USER)@$(HOSTNAME).activationPackage
	$(shell nix path-info .#homeConfigurations.$(USER)@$(HOSTNAME).activationPackage)/activate

.PHONY: build-hm
build-hm: ## Build Home-Manager configuration
	home-manager build --flake .#$(USER)@$(HOSTNAME) $(NOM)

.PHONY: build-hm-dry-run
build-hm-dry-run: ## Build Home-Manager configuration (dry-run)
	home-manager build --flake .#$(USER)@$(HOSTNAME) --dry-run

.PHONY: switch-hm
switch-hm: ## Switch Home-Manager configuration
	home-manager switch --flake .#$(USER)@$(HOSTNAME)

.PHONY: news-hm
news-hm: ## Home-Manager news
	home-manager news --flake .#$(USER)@$(HOSTNAME)

.PHONY: build
build: build-nixos build-hm ## Build

.PHONY: build-dry-run
build-dry-run: build-nixos-dry-run build-hm-dry-run ## Build (dry-run)

.PHONY: build-diff
build-diff: ## Show configuration diff
	nvd diff /run/current-system ./result
# Built-in alternative to `nvd`
# nix store diff-closures /run/current-system ./result

.PHONY: modify-secrets
modify-secrets: ## Modify secrets
	nix shell nixpkgs#sops -c sops --indent 2 secrets/secrets.yaml

.PHONY: update-secrets
update-secrets: ## Update secrets for added/removed keys
	nix shell nixpkgs#sops -c sops --indent 2 updatekeys secrets/secrets.yaml

.PHONY: test
test: ## Test
	nix flake check

.PHONY: hooks
hooks: ## Run hooks
	nix develop --command pre-commit run --all-files

.PHONY: format
format: ## Format source
	nix fmt

.PHONY: lock
lock: ## Update lock file
	nix flake update

.PHONY: clean
clean: ## Garbage collect
	nix-collect-garbage --delete-older-than 30d

.PHONY: help
help: ## This menu
	@grep -P "##\s(.*)$$" $(MAKEFILE_LIST) | sed 's/:.*##/:/'
