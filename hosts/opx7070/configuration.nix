{ config, outputs, pkgs, lib, ... }:

{
  imports = [
    ../../modules
    ../common/desktop-cinnamon.nix
    ../common/localisation.nix
    ../common/users-groups.nix
    ./backups.nix
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

  # Filesystem support
  boot.supportedFilesystems = [ "ntfs" "zfs" ];
  boot.zfs.forceImportRoot = false; # Recommended setting
  services.zfs.autoScrub = {
    enable = true;
    interval = "*-*-1,15 04:00:00"; # 1st and 15th of every month at 4am
  };

  # Networking
  networking.hostName = "opx7070";
  networking.networkmanager.enable = true;
  # Required for ZFS
  networking.hostId = "6b3f7344"; # `head -c4 /dev/urandom | od -A none -t x4`
  services.tailscale = {
    enable = true;
    extraUpFlags = [
      "--accept-dns=false"
    ];
  };
  # Workaround - Tailscale causing NetworkManager-wait-online to fail on start
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

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
      # Chrony NTP client and server
      chrony =
        {
          enable = true;
          # Enable server functionality and allow access from local network
          extraConfig = "allow 192.168.0.0/16";
        };
      # Gatus
      gatus = {
        enable = true;
        openFirewall = true;
        package = pkgs.unstable.gatus;
        configFile = config.sops.secrets."gatus".path;
      };
      # Garbage collection
      gc.enable = true;
      # Glances monitoring service
      glances.enable = true;
      # Podman virtualisation
      podman.enable = true;
      # Slimserver / LMS / Lyrion
      slimserver = {
        enable = true;
        package = pkgs.unstable.slimserver;
      };
      # SSH server
      ssh.enable = true;
      # Home Assistant
      hass = {
        enable = true;
        extraOptions = [
          "--network=host"
        ];
        # https://github.com/home-assistant/core/releases
        image = "ghcr.io/home-assistant/home-assistant:2025.4.4";
        # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/zi/zigbee2mqtt/package.nix
        z2mPackage = pkgs.unstable.zigbee2mqtt_1;
      };
    };
  };

  # Secrets
  sops = {
    secrets = {
      gatus = { };
      "mqtt/valetudo/larry/password" = { };
      "mqtt/valetudo/harry/password" = { };
    };
  };

  # Release version of first install
  system.stateVersion = "24.05";
}
