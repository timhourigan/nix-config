{
  description = "Nix Configuration, including Home-Manager";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pinning to zigbee2mqtt 2.9.2 - https://github.com/NixOS/nixpkgs/pull/505798
    nixpkgs-pinned.url = "github:nixos/nixpkgs?rev=717b057ab3b143d670873434b1ec7dc170ad628f";

    # Community packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix Secrets Management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Treefmt
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-Commit Hooks
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # FIXME - Others to consider
    # Hardware
    # hardware.url = "github:nixos/nixos-hardware";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      pre-commit-hooks,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      # NixOS Configurations
      nixosConfigurations = {
        bri7 = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/bri7/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        m625q = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/m625q/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        mm = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/mm/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        opx7070 = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/opx7070/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        sid = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/sid/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        t490 = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/t490/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        x13 = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/x13/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
      };

      # Home-Manager Configurations
      homeConfigurations = {
        # Test hosts
        "timh@aarch64darwin-t" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = [
            ./home
            ./home/hosts/aarch64darwin-t
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@aarch64linux-t" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux;
          modules = [
            ./home
            ./home/hosts/aarch64linux-t
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@amd64linux-t" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home
            ./home/hosts/amd64linux-t
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        # Physical hosts
        "timh@bri7" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home
            ./home/hosts/bri7
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@m625q" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home
            ./home/hosts/m625q
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@mm" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home
            ./home/hosts/mm
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@opx7070" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home
            ./home/hosts/opx7070
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@sid" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home
            ./home/hosts/sid
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@t490" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home
            ./home/hosts/t490
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@x13" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home
            ./home/hosts/x13
          ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
      };

      # Home Manager Modules (for consumption by other flakes)
      homeManagerModules.default = import ./modules/home;

      # Overlays
      overlays = import ./overlays { inherit inputs; };

      # Dev Shells
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit) shellHook;
          };
        }
      );

      # Formatter Configuration
      formatter = forAllSystems (
        system:
        inputs.treefmt-nix.lib.mkWrapper nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";
          programs = {
            # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
            actionlint.enable = true;
            deadnix.enable = true;
            nixfmt.enable = true;
            mdformat.enable = true;
            statix.enable = true;
          };
        }
      );

      # Checks
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          pre-commit = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              # https://github.com/cachix/git-hooks.nix?tab=readme-ov-file#hooks
              # https://github.com/cachix/git-hooks.nix/blob/master/modules/hooks.nix
              # Editors
              editorconfig-checker = {
                enable = true;
                excludes = [
                  "flake.lock"
                ];
              };
              # GitHub Actions
              actionlint.enable = true;
              # Makefile
              checkmake.enable = true;
              # Markdown
              markdownlint.enable = true;
              # Nix
              deadnix.enable = true;
              flake-checker = {
                enable = true;
                args = [ "--no-telemetry" ];
              };
              nixfmt.enable = true;
              statix = {
                enable = true;
                settings.ignore = [ "**/hardware-configuration.nix" ];
              };
              # Secrets
              trufflehog = {
                enable = true;
                # https://github.com/trufflesecurity/trufflehog/blob/6961f2bace57ab32b23b3ba40f8f420f6bc7e004/.pre-commit-hooks.yaml#L4
                entry =
                  pkgs.lib.getExe pkgs.trufflehog
                  + " git file://. --since-commit HEAD --results=verified --fail --trust-local-git-config";
              };
              ripsecrets.enable = true;
              # Shell
              shellcheck.enable = true;
              # Spelling
              typos = {
                enable = true;
                settings.exclude = "secrets/*";
              };
              # YAML
              yamllint.enable = true;
            };
          };
        }
      );
    };
}
