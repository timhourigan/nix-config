{
  description = "Nix Configuration, including Home-Manager";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Firefox Addons
    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";

    # FIXME - Others to consider
    # Hardware
    # hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs: {
    # NixOS Configurations
    nixosConfigurations = {
      x1c = nixpkgs.lib.nixosSystem {
        modules = [ ./hosts/x1c/configuration.nix ];
      };
      x13 = nixpkgs.lib.nixosSystem {
        modules = [ ./hosts/x13/configuration.nix ];
      };
    };

    # Home-Manager Configurations
    homeConfigurations = {
      "timh@x1c" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };
      "timh@x13" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home/home.nix ];
        extraSpecialArgs = { inherit inputs; };
      };
    };

    # Formatter Configuration
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
  };
}
