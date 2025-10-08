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
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Filesystem support
  boot.supportedFilesystems = [ "ntfs" "zfs" ];
  boot.zfs.forceImportRoot = false; # Recommended setting
  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-1,15 04:00:00"; # 1st and 15th of every month at 4am
  };

  # Networking
  networking = {
    hostName = "sid";
    networkmanager.enable = true;
    # Required for ZFS
    hostId = "eef01409"; # `head -c4 /dev/urandom | od -A none -t x4`
  };

  # Allow vscode code server to work
  programs.nix-ld.enable = true;

  # Modules
  modules = {
    desktops.xfce.enable = true;
    secrets.sops-nix.enable = true;
    services = {
      avahi.enable = true;
      gc.enable = true;
      glances.enable = true;
      ssh.enable = true;
    };
    system.autoUpgrade = {
      enable = true;
      dates = "03:00";
      flake = "github:timhourigan/nix-config";
    };
  };

  # Secrets
  sops = {
    secrets = { };
  };

  # Release version of first install
  system.stateVersion = "24.11";
}
