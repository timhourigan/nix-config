{
  description = "Nix Configuration, including Home-Manager";

  nixConfig = {
    extra-substituters = [
     "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

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

    # Firefox Addons
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

    # FIXME - Others to consider
    # Hardware
    # hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
    in
    {
      # NixOS Configurations
      nixosConfigurations = {
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
      };
    };
}
