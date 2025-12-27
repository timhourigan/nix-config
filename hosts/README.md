# Hosts

## Adding a new host

### On existing host

- Create a new branch in the `nix-config` repository

- Create a folder for the new host configuration, `hosts/<hostname>`

  - Copy a `configuration.nix` from an existing host and tweak as necessary,
    changing `hostName` at a minimum

- Create a folder for the new host home manager, `home/hosts/<hostname>`

  - Copy a directory from an existing host

- Add the NixOS configuration for the host to `flake.nix`

  ```shell
  <hostname> = nixpkgs.lib.nixosSystem {
  modules = [ ./hosts/<hostname>/configuration.nix ];
  specialArgs = { inherit inputs outputs; };
  };
  ```

- Add the Home Manager configuration for the user to `flake.nix`

  ```shell
  "<username>@<hostname>" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home ./home/hosts/<hostname> ];
      extraSpecialArgs = { inherit inputs outputs; };
  };
  ```

- Update the lock file

  ```shell
  make lock
  ```

- Update the matrix in `.github/workflows/build-home-manager.yaml` to
  include the new host

- Update the matrix in `.github/workflows/build-nixos.yaml` to include the new host

- Commit the changes to a branch

### On new host

- Install NixOS on the new host, using a bootable USB

  - Dependent on the hardware, it may be necessary to try different USB options
    e.g. Ventoy, dd copied image, Balena Etcher copied image

- Login and temporarily install `vim`

  ```shell
  nix-shell -p vim
  ```

- Modify the `/etc/nixos/configuration.nix` with `sudo vim`

  - To change the hostname to the new name
  - To enable SSH
  - Install git gnumake vim

- Clone this repository to `~/git/nix-config`

- Run `nixos-generate-config --show-hardware-config > ~/git/nix-config/hosts/<hostname>/hardware-configuration.nix`

- Build the changes and switch to them

  ```shell
  cd ~/git/nix-config
  sudo nixos-rebuild switch
  ```

- Commit the changes to the branch

### Secrets

- If secrets are needed, run the following command and add it under a new host
  and update the secrets

  ```shell
  nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
  make update-secrets
  ```

- Commit the changes to the branch
