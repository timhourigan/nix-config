{
  description = "Nix Configuration, including Home-Manager";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pinning to zigbee2mqtt 2.6.1 - https://github.com/NixOS/nixpkgs/pull/439341
    nixpkgs-pinned.url = "github:nixos/nixpkgs?rev=55c49510f6a774e48b22249b063bb25537737321";

    # Community packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
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

  outputs = { self, nixpkgs, home-manager, pre-commit-hooks, ... }@inputs:
    let
      inherit (self) outputs;
    in
    {
      # NixOS Configurations
      nixosConfigurations = {
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
        x1c = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/x1c/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
        x13 = nixpkgs.lib.nixosSystem {
          modules = [ ./hosts/x13/configuration.nix ];
          specialArgs = { inherit inputs outputs; };
        };
      };

      # Home-Manager Configurations
      homeConfigurations = {
        "timh@m625q" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home/home.nix ./home/hosts/m625q ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@mm" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home/home.nix ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@opx7070" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home/home.nix ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@sid" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home/home.nix ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@x1c" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home/home.nix ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
        "timh@x13" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home/home.nix ./home/workstation.nix ];
          extraSpecialArgs = { inherit inputs outputs; };
        };
      };

      # Overlays
      overlays = import ./overlays { inherit inputs; };

      # Dev Shells
      devShells.x86_64-linux = {
        default = with nixpkgs.legacyPackages.x86_64-linux; mkShell {
          inherit (self.checks.x86_64-linux.pre-commit) shellHook;
          buildInputs = self.checks.x86_64-linux.pre-commit.enabledPackages;
        };
      };

      # Formatter Configuration
      formatter.x86_64-linux =
        inputs.treefmt-nix.lib.mkWrapper
          inputs.nixpkgs.legacyPackages.x86_64-linux
          {
            projectRootFile = "flake.nix";
            programs = {
              # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#supported-programs
              actionlint.enable = true;
              deadnix.enable = true;
              nixpkgs-fmt.enable = true;
              mdformat.enable = true;
              statix.enable = true;
            };
          };

      # Checks
      checks.x86_64-linux = with nixpkgs.legacyPackages.x86_64-linux; {
        pre-commit = pre-commit-hooks.lib.x86_64-linux.run {
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
            flake-checker =
              {
                enable = true;
                args = [ "--no-telemetry" ];
              };
            nixpkgs-fmt.enable = true;
            statix = {
              enable = true;
              settings.ignore = [ "**/hardware-configuration.nix" ];
            };
            # Secrets
            trufflehog.enable = true;
            ripsecrets.enable = true;
            # Shell
            shellcheck.enable = true;
            # Spelling
            typos = {
              enable = true;
              settings.exclude =
                "secrets/*";
            };
            # YAML
            yamllint.enable = true;
          };
        };
      };
    };
}
