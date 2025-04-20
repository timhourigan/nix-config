{ config, outputs, pkgs, lib, ... }:

{
  imports = [
    ../../modules/services/avahi.nix
    ../../modules/services/gc.nix
    ../../modules/secrets/sops-nix.nix
    ../../modules/services/glances.nix
    ../../modules/services/podman.nix
    ../../modules/services/ssh.nix
    ../common/desktop-xfce.nix
    ../common/localisation.nix
    ../common/users-groups.nix
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    overlays = [
      # Allow unstable packages at unstable.<package>
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Use `nixos-option` to see configuration options e.g. `nixos-option service.<service-name>`

  # Feature configuration
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow packages to be pushed from other systems e.g.
  # nixos-rebuild build --target-host <hostname> --flake .
  nix.settings.trusted-users = [ "timh" ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Networking
  networking.hostName = "m625q";
  networking.networkmanager.enable = true;
  # Don't want wireless
  networking.wireless.enable = false;

  # System packages
  environment.systemPackages = with pkgs; [
    bash-completion
    git
    gnumake
    vim
    wget
  ];

  # Allow vscode code server to work
  programs.nix-ld.enable = true;

  # Modules
  modules = {
    secrets = {
      # sops-nix secrets management
      sops-nix.enable = true;
    };
    services = {
      # Avahi service discovery
      avahi.enable = true;
      # Garbage collection
      gc.enable = true;
      # Glances monitoring service
      glances.enable = true;
      # Podman virtualisation
      podman.enable = true;
      # SSH server
      ssh.enable = true;
    };
  };

  # Secrets
  sops = {
    secrets = { };
  };

  # Release version of first install
  system.stateVersion = "22.05";
}
