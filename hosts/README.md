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

- Commit the changes to a branch
- On the new host, temporarily install `vim`

  ```shell
  nix-shell -p vim
  ```

- Modify the `/etc/nixos/configuration.nix` with `sudo vim`
  - To change the hostname to the new name
  - To enable SSH
- Build the changes and switch to them

  ```shell
  sudo nixos-rebuild switch
  ```

- Copy the installation configurations to a different host

```shell
scp <username>@<ip-address>:/etc/nixos/configuration.nix ./hosts/<hostname>/configuration-installer.nix
# Replacing the existing
scp <username>@<ip-address>:/etc/nixos/hardware-configuration.nix ./hosts/<hostname>/hardware-configuration.nix
```
- Update `boot.loader` in `./hosts/<hostname>/configuration.nix` to match the settings in `configuration-installer.nix` and delete `configuration-installer.nix`
- Commit the changes to the branch
- SSH to the new host
- Check out the changes on the new host
- On the new host, temporarily install `git` and `GNU make`

  ```shell
  nix-shell -p git gnumake
  ```
