{
  description = "Nix Configuration, including Home-Manager";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Community packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix Secrets Management
    sops-nix = {
      url = "github:Mic92/sops-nix";
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
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

      # Checks
      checks.x86_64-linux = with nixpkgs.legacyPackages.x86_64-linux; {
        checkmake = runCommand "checkmake"
          {
            buildInputs = [ checkmake ];
          }
          ''
            mkdir $out
            checkmake ${./Makefile}
          '';
        markdownlint = runCommand "mdl"
          {
            buildInputs = [ mdl ];
          }
          ''
            mkdir $out
            mdl ${./README.md}
          '';
        pre-commit = pre-commit-hooks.lib.x86_64-linux.run {
          src = ./.;
          # TODO - Re-enable
          hooks = {
            # https://github.com/cachix/git-hooks.nix?tab=readme-ov-file#hooks
            # Formatters
            # TODO - Enable Prettier
            # prettier.enable = true;
            # Editors
            # editorconfig-checker.enable = true;
            # Makefile
            # checkmake.enable = true;
            # Markdown
            # markdownlint.enable = true;
            # # Nix
            # deadnix.enable = true;
            # flake-checker =
            #   {
            #     enable = true;
            #     args = [ "--no-telemetry" ];
            #   };
            # nixpkgs-fmt.enable = true;
            # statix.enable = true;
            # # Secrets
            # trufflehog.enable = true;
            # # Shell
            # shellcheck.enable = true;
            # # Spelling
            # typos.enable = true;
            # # YAML
            # yamllint.enable = true;
          };
        };
      };
    };
}
