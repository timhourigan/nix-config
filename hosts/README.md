# Hosts

## Adding a new host

- Install NixOS on the new host, using a bootable USB
  - Dependent on the hardware, it may be necessary to try different USB options e.g. Ventoy, dd copied image, Balena Etcher copied image
- Create a host folder in `./hosts`, this can be initially based on an existing host
  - Update `networking.hostName` in `configuration.nix` to the new host's name
  - Update `system.stateVersion` to `configuration.nix` the installed version of NixOS
  - Add the NixOS configuration for the host to `flake.nix`

    ```shell
    <hostname> = nixpkgs.lib.nixosSystem {
    modules = [ ./hosts/hostname/configuration.nix ];
    specialArgs = { inherit inputs outputs; };
    };
    ```

  - Add the Home Manager configuration for the user to `flake.nix`

    ```shell
    "<username>@<hostname>" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home/home.nix ];
        extraSpecialArgs = { inherit inputs outputs; };
    };
    ```
  - Update the matrix in `.github/workflows/build-home-manager.yaml` to include the new host
  - Update the matrix in `.github/workflows/build-nixos.yaml` to include the new host

- Commit the changes to a branch and check out the changes on the new host
- TODO - sops
