# nix-config

NixOS and Home-Manager configuration.

## Update NixOS Configuration

* Build:

```shell
nixos-rebuild build --flake .#<hostname>
```

* Switch (usually requires `sudo`):

```shell
nixos-rebuild switch --flake .#<hostname>
```

## Update Home-Manager Configuration

* Build:

```shell
home-manager build --flake .#<username>@<hostname>
```

* Switch:

```shell
home-manager switch --flake .#<username>@<hostname>
```

## Update flake.lock file

```shell
nix flake update
```

## Make Options

```shell
$ make
build-nixos: Build NixOS configuration
switch-nixos: Switch NixOS configuration
bootstrap-hm: Bootstrap Home-Manager configuration
build-hm: Build Home-Manager configuration
switch-hm: Switch Home-Manager configuration
format: Format source
lock: Update lock file
gc: Garbage collect
help: This menu
```
