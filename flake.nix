{
  description = "Nix Configuration, including Home-Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-colors.url = "github:misterio77/nix-colors";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {

    # Install packages in /etc/profiles
    # Necessary to use 'nixos-rebuild build-vm'
    # home-manager.nixosModules.home-manager.useUserPackages = true;
    # Use the global pkgs that is configured via
    # the system level nixpkgs options
    # home-manager.nixosModules.home-manager.useGlobalPkgs = true;

    # NixOS Configurations
    nixosConfigurations = {
      media = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/proxmox-image.nix"
          ./hosts/media
          ./hosts/media/proxmox.nix
          {
            nixpkgs.hostPlatform = "x86_64-linux";
          }
        ];
      };
      # FIXME I'm not sure how to allow image creation, along with follow up configuration changes
      rocinante = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/rocinante
          "${nixpkgs}/nixos/modules/virtualisation/proxmox-image.nix"
          ./hosts/rocinante/proxmox.nix
          #   ./home/home.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.drn = {
                home.homeDirectory = "/home/drn";
                home = {
                  username = "drn";
                  stateVersion = "24.05";
                };
              };
            };
          }
        ];
        specialArgs = {
          # pkgs = pkgs;
          diskSize = 128 * 1024;
          bootSize = 512;
          memorySize = 1024 * 8;
        };
      };
      # Application-agnostic single-node k3s platform (first app: fitness).
      # See hosts/app-node/README.md.
      app-node = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/app-node
          "${nixpkgs}/nixos/modules/virtualisation/proxmox-image.nix"
          ./hosts/app-node/proxmox.nix
        ];
      };

      # Edge Router (CWT N18 Mini PC) — Data Plane. Firewall/NAT/DHCP/DNS.
      # See hosts/edge-router/README.md.
      edge-router = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/edge-router
          ./hosts/edge-router/hardware-configuration.nix
        ];
      };

      # Management Server (ThinkStation) — Management Plane.
      # UniFi + Prometheus + Grafana. See hosts/mgmt/README.md.
      mgmt = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mgmt
          ./hosts/mgmt/hardware-configuration.nix
        ];
      };

      # Media Server (Proxmox VM) — Jellyfin + the *arr stack + Tailscale.
      # See hosts/media/README.md.
    };

    # Home-Manager Configurations (standalone — also the way non-NixOS
    # machines like the Fedora laptop are brought under management)
    homeConfigurations = {
      "mac@personal" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home/home.nix
          {
            home.username = "mac";
            home.homeDirectory = "/home/mac";
          }
        ];
        # extraSpecialArgs = { inherit nix-colors; };
      };
      "drn@dev" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home/home.nix
          {
            home.username = "drn";
            home.homeDirectory = "/home/drn";
          }
        ];
      };
      "rocinante" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home/home.nix
          {
            home.username = "drn";
            home.homeDirectory = "/home/drn";
          }
        ];
      };
      # This Fedora laptop (darrenmeehan@fedora)
      "darrenmeehan@fedora" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home/home.nix
          # Laptop-specific bits: keep the shell env and git auth that this
          # machine already has, instead of throwing them away on switch.
          {
            home.username = "darrenmeehan";
            home.homeDirectory = "/home/darrenmeehan";

            # Preserve the environment the hand-written ~/.bashrc exports
            programs.bash.bashrcExtra = ''
              . /etc/bashrc
              # Up/Down: search history by the current command prefix (type
              # a few chars, then arrow through matches)
              bind '"\e[A": history-search-backward'
              bind '"\e[B": history-search-forward'
              export ANDROID_HOME=/usr/local/android-sdk
              export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
              export PATH=$PATH:$ANDROID_HOME/platform-tools
              export CAPACITOR_ANDROID_STUDIO_PATH=$ANDROID_HOME/cmdline-tools/latest/bin
              export FLYCTL_INSTALL="/home/darrenmeehan/.fly"
              export PATH="$FLYCTL_INSTALL/bin:$PATH"
              . "$HOME/.cargo/env"
              export PODMAN_COMPOSE_WARNING_LOGS=false
              # bun (was in the hand-written ~/.bash_profile)
              export BUN_INSTALL="$HOME/.bun"
              export PATH="$BUN_INSTALL/bin:$PATH"
              export PATH="/home/darrenmeehan/.local/bin:$PATH"
            '';

            # Same env for zsh (login shell as of 2026-01); home-switch not
            # sourced from bashrc anymore
            programs.zsh = {
              shellAliases = {
                home-switch = "home-manager switch --flake \"$HOME/code/nix-config#\$USER@\$(hostname)\" -b backup";
                hm = "home-switch";
              };
              envExtra = ''
                export ANDROID_HOME=/usr/local/android-sdk
                export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
                export PATH=$PATH:$ANDROID_HOME/platform-tools
                export CAPACITOR_ANDROID_STUDIO_PATH=$ANDROID_HOME/cmdline-tools/latest/bin
                export FLYCTL_INSTALL="/home/darrenmeehan/.fly"
                export PATH="$FLYCTL_INSTALL/bin:$PATH"
                export PODMAN_COMPOSE_WARNING_LOGS=false
                [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
                export BUN_INSTALL="$HOME/.bun"
                export PATH="$BUN_INSTALL/bin:$PATH"
                export PATH="/home/darrenmeehan/.local/bin:$PATH"
              '';
            };
          }
        ];
      };
    };

    # Formatter Configuration
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

    # Host 1 (edge-router) build artifacts.
    #   nix build .#edge-router-iso        → bootable USB installer ISO
    packages.x86_64-linux = {

      # Bootable USB installer ISO — built natively by nixpkgs (the old
      # `nixos-generators` input was dropped; `installation-cd-base.nix` is the
      # same base the upstream `install-iso` format wraps).
      edge-router-iso = (nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/edge-router
          ./hosts/edge-router/hardware-configuration.nix
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
          # Silences the 26.11 `boot.zfs.forceImportRoot` default-warning (we
          # don't use ZFS; false is also the new upstream-safe default).
          { boot.zfs.forceImportRoot = false; }
        ];
      }).config.system.build.isoImage;
    };
  };
}
