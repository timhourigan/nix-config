{ config, outputs, pkgs, lib, ... }:

{
  imports = [
    ../../modules/services/gc.nix
    ../../modules/secrets/sops-nix.nix
    ../../modules/services/glances.nix
    ../../modules/services/ssh.nix
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

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Filesystem support
  boot.supportedFilesystems = [ "ntfs" "zfs" ];
  boot.zfs.forceImportRoot = false; # Recommended setting
  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-1,15 04:00:00"; # 1st and 15th of every month at 4am
  };

  # Networking
  networking.hostName = "sid";
  networking.networkmanager.enable = true;
  # Required for ZFS
  networking.hostId = "eef01409"; # `head -c4 /dev/urandom | od -A none -t x4`

  # Localisation
  time.timeZone = "Europe/Dublin";
  i18n.defaultLocale = "en_IE.utf8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };

  # Configure console keymap
  console.keyMap = "ie";

  # X11
  services.xserver = {
    enable = true;
    xkb = {
      layout = "ie";
      variant = "";
    };
  };

  # Desktop - Cinnamon
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.cinnamon.enable = true;

  # Remote Desktop - Xrdp - Commented out for now
  # services.xrdp.enable = true;
  # services.xrdp.defaultWindowManager = "/run/current-system/sw/bin/cinnamon";
  # networking.firewall.allowedTCPPorts = [ 3389 ];

  users.users.timh = {
    isNormalUser = true;
    description = "timh";
    # Networking: "networkmanager"
    # sudo: "wheel"
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdPJVS2P6fNEMuIAuJqCMtqLU4LAI50SeoAF5GyCFFl"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC/Tztty6abMFos05TQbanvo+Y6uwZKNnhG1I+bkikgzeM7+Tz9Vx5xlodTqko71Ipn/dR66mpyADaPV0kE1MPdK7oBZdxaDKBGD/zo1Rm3fH4BVPk5z0g7cwaBKNRq8UvNcFy10ksNCeDZQYfMdWXnpYUj7WYjsIAmOV+FARz6NakmAsCh/A7vzBsFoFZ4JzayE/vGCHdQc1ecw6QF40yBqZA8Ufpft//VG2SfXPoLHlYFdTxp4AjvlMJ2mjoDnBem1n+6aBl2qMDA7PQqFse2mJLZhnCncuLImJH05rwCCPf1wEb1NpzpLwvPBt8cTNx/S/hJ4fQ5fmsxJlkzUdvOPCDM9yy/ITg++hrJHPGA9sdXRuO42OKoT25U65fCFM2PzrmSTPRLRsR4KxiPvMay4fQS4JfAOD5LOrecuLYMiL1rJrjzp/IaIgF5CylVx5NFlA4AzicmNI2A5/I2YeBX3yc2IAhcMjgTRYUbI0H9P21g4Yre+o4CSjuhmoO27eBtb4M02OnGXhzg7IsASDmyQRwJbqNyFAYnmS9tSX7H7BQ/+DbC7vak2sNidnJ8hc2jGtauQwsUeZlalYy3NM+ePL7eCm6GnYNQOFnnzAlYKBSTw+NymJY7WYOeb+woe2pgOPzK7fLggXgxxVlrsYpwbG1KyrCBP3l+Ie3HdCLxuw=="
    ];
  };

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
      # Garbage collection
      gc.enable = true;
      # Glances monitoring service
      glances.enable = true;
      # SSH server
      ssh.enable = true;
    };
  };

  # Secrets
  sops = {
    secrets = { };
  };

  # Release version of first install
  system.stateVersion = "24.11";
}
