{ config, outputs, ... }:

{
  imports = [
    ../../modules
    ../common
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

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking = {
    hostName = "bri7";
    networkmanager.enable = true;
  };


  # Modules
  modules = {
    desktops.xfce.enable = true;
    secrets.sops-nix.enable = true;
    services = {
      avahi.enable = true;
      glances.enable = true;
      ssh.enable = true;
    };
    system = {
      autoUpgrade = {
        enable = true;
        dates = "05:00";
        flake = "github:timhourigan/nix-config";
      };
      gc = {
        enable = true;
        options = "--delete-older-than 30d";
      };
    };
  };

  # Secrets
  sops = {
    secrets = { };
  };

  # Release version of first install
  system.stateVersion = "25.05";
}
